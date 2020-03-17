module Songs

using AWSCore: aws_config
using AWSS3: s3_get_file
using Base.Filesystem: dirname, mkdir, ispath, basename, joinpath
using ZipFile: Reader, read
using CSV, InfoZIP

BUCKET_NAME = "maxwell-main"
LYRICS_ZIPNAME = "data/380000-lyrics-from-metrolyrics.zip"
LOCAL_DATA_DIR = "data"
DEFAULT_DATA_FPATH = "$(LOCAL_DATA_DIR)/$(basename(LYRICS_ZIPNAME))"
VERBOSE = true
function download(; s3bucket = BUCKET_NAME, s3path = LYRICS_ZIPNAME,
                  outpath = DEFAULT_DATA_FPATH)        
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

function unzip(zippath = DEFAULT_DATA_FPATH)
    #r = Reader(zippath)
    ##for (i, f) in enumerate(r.files)
    ##    if i > 2
    ##        error("Only expected one file in the zip, but got more.")
    ##    end
    ##    name = f.name
    ##    full_fpath = joinpath(dirname(zippath), f.name)
    ##    if !isfile(full_fpath)
    ##        open(full_fpath, "w") do handle
    ##            write(handle, read(f, String))
    ##        end
    ##    end
    ##end
    #a_file_in_zip = filter(x -> x.name == "lyrics.csv", r.files)[1]
    #return CSV.read(a_file_in_zip)
    return open_zip(zippath)["lyrics.csv"]
end

function describe(path)
    
end

download()
data = unzip()

println(data)

# describe(datapath)

end
