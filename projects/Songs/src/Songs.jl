module Songs

using AWSCore: aws_config
using AWSS3: s3_get_file
using Base.Filesystem: dirname, mkdir, ispath, basename, joinpath
# using ZipFile: Reader, read
using CSV, DataFrames, DataFramesMeta, Statistics, Unicode

BUCKET_NAME = "maxwell-main"
LYRICS_ZIPNAME = "data/380000-lyrics-from-metrolyrics.zip"
LOCAL_DATA_DIR = "data"
DEFAULT_DATA_FPATH = "$(LOCAL_DATA_DIR)/$(basename(LYRICS_ZIPNAME))"
VERBOSE = true
function download(; s3bucket = BUCKET_NAME, s3path = LYRICS_ZIPNAME,
                  outpath = DEFAULT_DATA_FPATH)
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
    data[!, :group] = [p <= train_prop ? "train" : "test"
                       for p in data[!, :song_prop]]
    return data
end

standardize(lyrics::Array{Union{String, Missing}, 1}) = map(lyrics) do s
    if ismissing(s)
        return s
    else
        s = string(s)
        s = Unicode.normalize(s, stripmark = true)
        s = Unicode.lowercase(s)
        s = replace(s, r"[\n]" => " ")
        return s
    end
end

function read_and_process_data(;max_rows::Int = 10000,
                               train_prop::Float64 = 0.80)::DataFrame    
    data = first(CSV.read("data/lyrics.csv"),
                 max_rows)
    data = filter(row -> !ismissing(row[:lyrics]), data)
    data[!, :lyrics] = standardize(data[!, :lyrics])
    data = mark_train_test_by_artist(data, train_prop)
    data[!, :rowid] = 1:nrow(data)
    return data
end

end
