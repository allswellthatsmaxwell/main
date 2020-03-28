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

struct CharMap
    """ Maps characters in song lyrics to integers. """
    d::Dict{Char, Int}
end

struct ArtistMap
    """ Maps artist names to integers. """
    d::Dict{String, Int}
end

struct ModelConfig
    in::Int
    out::Int
    pad::Int
end

struct ModelData
    X::Array{Int, 2}
    Y::Flux.OneHotMatrix{Array{Flux.OneHotVector, 1}}
    cfg::ModelConfig
end

function ModelData(df::DataFrame)
    cfg = ModelConfig(df)
    Y = Flux.onehotbatch(df[!, :artist], unique(df[!, :artist]))
    cmap = CharMap(df[!, :lyrics])
    encoded_lyrics = encode_and_pad(cmap, df[!, :lyrics], cfg)
    X = hcat(encoded_lyrics...)
    return ModelData(X, Y, cfg)
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


function read_and_process_data(;max_rows::Int = 10000,
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
        #s = Unicode.lowercase(s)
        #s = replace(s, r"[\n.,?!;]" => " ")
        #s = replace(s, r"[^a-zA-Z0-9 ]" => "")
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
    representations, and pads its length to the in length in the config.
    """

    unpadded::Array{Int, 1} = encode(charmap, songtext)
    remaining::Int = cfg.in - length(unpadded)
    padding = repeat([cfg.pad], remaining)
    return vcat(unpadded, padding)   
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

ModelConfig(in::Int, out::Int) = ModelConfig(in, out, 0)

function ModelConfig(df::DataFrame)
    max_obs_len = maximum(map(length, df[!, :lyrics]))
    n_artists = length(unique(df[!, :artist]))
    return ModelConfig(max_obs_len, n_artists)
end

function construct_model(in::Int, out::Int)
    return Chain(Dense(in,  out, tanh),
                 Dense(out, out, relu),
                 Dense(out, out, tanh),
                 Dense(out, out, relu),
                 Dense(out, out, tanh),
                 Dense(out, out, softmax))
end

construct_model(cfg::ModelConfig) = construct_model(cfg.in, cfg.out)

data(mdata::ModelData) = zip(mdata.X, mdata.Y)

function Flux.train!(m::Flux.Chain, trn::ModelData, tst::ModelData)
    loss(x, y) = crossentropy(m(x), y)
    opt = Flux.ADAM()
    trn_batches = Flux.Data.DataLoader(trn.X, trn.Y, batchsize = 1024) 
    evalcb() = @show(loss(tst.X, tst.Y))
    
    Flux.train!(loss, params(m), trn_batches, opt, cb = Flux.throttle(evalcb, 5))
end

function getvars()
    df = read_and_process_data()
    ## TODO: need to match input len between train and test.
    trn = ModelData(filter(row -> row[:group] == TRN_IND, df))
    tst = ModelData(filter(row -> row[:group] == TST_IND, df))
    m = construct_model(trn.cfg)
    return df, trn, tst, m
end

#using Revise, Songs
#df, trn, tst, m = Songs.getvars();
#Songs.Flux.train!(m, trn, tst)

end
