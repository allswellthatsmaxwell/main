module Songs

using AWSCore: aws_config
using AWSS3: s3_get_file
using Base.Filesystem: dirname, mkdir, ispath, basename, joinpath
# using ZipFile: Reader, read
# using Statistics
using CSV, DataFrames, DataFramesMeta, Unicode
using Flux

BUCKET_NAME = "maxwell-main"
LYRICS_ZIPNAME = "data/380000-lyrics-from-metrolyrics.zip"
LOCAL_DATA_DIR = "data"
DEFAULT_DATA_FPATH = "$(LOCAL_DATA_DIR)/$(basename(LYRICS_ZIPNAME))"
VERBOSE = true

TRN_IND = "train"
TST_IND = "test"
UNKNOWN_ARTIST = "!unknown!"

struct CharMap
    """ Maps characters in song lyrics to integers. """
    d::Dict{Char, Int}
end

struct ArtistMap
    """ Maps artist names to integers. """
    d::Dict{String, Int}
end

struct ModelConfig
    """
    :param in: the number of features in the input.
    :param out: the number of artists.
    :param pad: the value used to indicate pad input
    lyrics that are shorter than the chosen input dimension.
    :param artists: the artists we're predicting.
    """
    in::Int
    out::Int
    pad::Int
    artists::Array{String, 1}
end

function ModelConfig(df::DataFrame)
    """
    Creates a config where the input dimension (i.e., the 
    number of characters used from a song when training/predicting
    on it) is the maximum observed length in df's :lyrics column,
    where the artists in scope to predict on are the unique artists
    present in df's :artist column, and the padding value is 0.
    """
    max_obs_len = maximum(map(length, df[!, :lyrics]))
    artists = unique(df[!, :artist])
    push!(artists, UNKNOWN_ARTIST)
    return ModelConfig(max_obs_len,
                       length(artists),
                       0,
                       artists)
end


struct ModelData
    """
    Holds input and output matrices, as well as model configuration,
    for artist prediction based on lyrics.
    """
    X::Array{Int, 2}
    Y::Flux.OneHotMatrix{Array{Flux.OneHotVector, 1}}
    cfg::ModelConfig
end

function ModelData(df::DataFrame, cfg::ModelConfig)
    """
    Constructs predictor and response matrices according
    to the input dataframe and config. If an artist in df
    is not known to the config, it gets bucketed into an unknown
    marker when being one-hot-encoded into the Y matrix.
    """
    rowwise_artists = [artist ∈ cfg.artists ? artist : UNKNOWN_ARTIST
                       for artist in df[!, :artist]]
    Y = Flux.onehotbatch(rowwise_artists, cfg.artists)
    cmap = CharMap(df[!, :lyrics])
    encoded_lyrics = encode_and_pad(cmap, df[!, :lyrics], cfg)
    X = hcat(encoded_lyrics...)
    return ModelData(X, Y, cfg)
end

function ModelData(df::DataFrame)
    """
    Constructs predictor and response matrices according
    to the input dataframe, also constructing its config
    from the input too. 
    """    
    cfg = ModelConfig(df)
    return ModelData(df, cfg)
end

function download(; s3bucket = BUCKET_NAME, s3path = LYRICS_ZIPNAME,
                  outpath = DEFAULT_DATA_FPATH)
    """ Downloads a file from AWS S3 to local disk. """
    ### doesn't work :/
    if !isfile(outpath)
        if VERBOSE
            println("Downloading $(s3bucket)/$(s3path) to $(outpath)...")
        end

        dir = dirname(outpath)
        if !ispath(dir) mkdir(dir) end
    
        aws = aws_config()
        s3_get_file(aws, s3bucket, s3path, outpath)
    end
end


function read_and_process_data(;max_rows::Int = 1000,
                               train_prop::Float64 = 0.80)::DataFrame
    """ 
    Reads the MetroLyrics file, removes rows where the lyrics are missing,
    does a little standardization on lyrics, and marks rows for train and test
    split.
    """
    data = first(CSV.read("data/lyrics.csv"),
                 max_rows)
    data = filter(row -> !ismissing(row[:lyrics]), data)
    data[!, :lyrics] = standardize(data[!, :lyrics])
    data = mark_train_test_by_artist(data, train_prop)
    data[!, :rowid] = 1:nrow(data)
    return data
end


function count_songs_per_artist(data::DataFrame)::DataFrame
    return by(data, :artist, :song => length) |>
        (df -> rename(df, :song_length => :n_songs))
end

function get_song_counts_quantiles(songs_per_artist::DataFrame)
    tiles = [[x for x in 0.10:0.10:0.9];
             [0.95, 0.975, 0.99, 0.995, 0.999, 1]]
    values = [floor(Int, x)
              for x in quantile(songs_per_artist[:n_songs], tiles)]
    return DataFrame(:percentile => tiles, :songs => values)
end

function describe(data::DataFrame)
    unique_artists::Int = length(unique(data[!, :artist]))
    songs_per_artist = count_songs_per_artist(data)
    quantiles = get_song_counts_quantiles(songs_per_artist)
    return unique_artists, quantiles
end

function mark_train_test_by_artist(data::DataFrame, train_prop::Float64)::DataFrame
    """
    Returns a new dataframe the same length as the input, with each row marked
    train or test. Splits are done within-artist. If an artist only has one song, 
    it goes in train (TODO: still need to check this).
    """
    ## We should shuffle the rows. Right now early songs go to train, later to test.
    data = @transform(groupby(data, :artist), 
                      song_ind = 1:length(:song),
                      n_songs = length(:song))
    data[!, :song_prop] = @with(data, :song_ind ./ :n_songs)
    data[!, :group] = [p <= train_prop ? TRN_IND : TST_IND
                       for p in data[!, :song_prop]]
    return data
end

standardize(lyrics::Array{Union{String, Missing}, 1}) = map(lyrics) do s
    if ismissing(s)
        return s
    else
        s = string(s)
        s = Unicode.normalize(s, stripmark = true)
        return s
    end
end

function CharMap(lyrics::Array{String, 1})
    d = Dict()
    i = 1
    for songtext in lyrics
        for char in songtext
            if char ∉ keys(d)
                d[char] = i
                i += 1
            end
        end
    end
    return CharMap(d)
end

encode(charmap::CharMap, songtext::String)::Array{Int, 1} = [
    charmap.d[c] for c in songtext]

encode(charmap::CharMap, songtexts::Array{String, 1})::Array{Array{Int, 1}, 1} =
    [encode(charmap, songtext) for songtext in songtexts]

function encode_and_pad(charmap::CharMap, songtext::String,
                        cfg::ModelConfig)::Array{Int, 1}
    """
    Maps the characters in a song to their integer 
    representations, and pads its length to the in length in the config 
    (if it's shorter than cfg.in) or truncates it down to that length 
    (if it's longer).
    """
    unpadded::Array{Int, 1} = encode(charmap, songtext)
    
    remaining::Int = cfg.in - length(unpadded)
    if length(unpadded) <= cfg.in
        padding = repeat([cfg.pad], remaining)
        result = vcat(unpadded, padding)
    else
        ## Longer than the configured input dim; truncate to make it match
        result = unpadded[1:cfg.in]
    end
    if length(result) != cfg.in
        error("bad input length calculation")
    end
    return result
end

function encode_and_pad(charmap::CharMap, songtexts::Array{String, 1},
                        cfg::ModelConfig)::Array{Array{Int, 1}, 1}
    """
    Maps the characters in each song in songtexts to their integer 
    representations, and makes sure they're all the same length.
    """
    return [encode_and_pad(charmap, songtext, cfg) for songtext in songtexts]
end

function ArtistMap(artists::Array{String, 1})
    d = Dict()
    i = 1
    for artist in artists
        if artist ∉ keys(d)
            d[artist] = i
            i += 1
        end
    end
    return ArtistMap(d)
end

encode(amap::ArtistMap, artists::Array{String, 1})::Array{Int, 1} = [
    amap.d[artist] for artist in artists]

function construct_model(in::Int, out::Int)
    return Chain(Dense(in,  out, tanh),
                 Dense(out, out, relu),
                 Dense(out, out, tanh),
                 Dense(out, out, relu),
                 Dense(out, out, tanh),
                 Dense(out, out),
                 softmax)
end

construct_model(cfg::ModelConfig) = construct_model(cfg.in, cfg.out)

data(mdata::ModelData) = zip(mdata.X, mdata.Y)

function Flux.train!(m::Flux.Chain, trn::ModelData, tst::ModelData;
                     epochs::Int = 10, batchsize::Int = 128)
    loss(x, y) = Flux.crossentropy(m(x), y)
    opt = Flux.ADAM()
    trn_batches = Flux.Data.DataLoader(trn.X, trn.Y, batchsize = batchsize)
    evalcb() = @show(loss(tst.X, tst.Y))
    for epoch in 1:epochs
        Flux.train!(loss, params(m), trn_batches, opt,
                    cb = Flux.throttle(evalcb, 5))
    end
end

function getvars(;max_rows::Int = 10000)
    df = read_and_process_data(max_rows = max_rows)
    ## TODO: need to match input len between train and test.
    trn = ModelData(filter(row -> row[:group] == TRN_IND, df))
    tst = ModelData(filter(row -> row[:group] == TST_IND, df),
                    trn.cfg)
    m = construct_model(trn.cfg)
    return df, trn, tst, m
end

#using Revise, Songs
#df, trn, tst, m = Songs.getvars();
#Songs.Flux.train!(m, trn, tst)

end
