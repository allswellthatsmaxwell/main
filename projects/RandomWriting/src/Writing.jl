module Writing

# using Turing

const TextList = Array{String, 1}

function process_text_file(path::String)
    open(path) do f
        text = read(f, String)
        # onegrams = get_kgrams(text, 1)
        textlist = clean_text_for_kgrams(text)
        println(textlist)
    end    
end

function _do_punct_separation(word)::Array
    puncts = split(".;,()-{}[]&*^%\$#@!\\/", "")
    for punct in puncts
        if endswith(word, punct)
            clean_word = replace(word, punct => "")
            return [clean_word, punct]
        end
    end
    return [word]
end

function _separate_punct(textlist)
    new_textlist = []
    for word in textlist
        result = _do_punct_separation(word)
        for word in result
            push!(new_textlist, word)
        end
    end
    return new_textlist
end


function clean_text_for_kgrams(text::String)
    text = lowercase(text)
    split_text = split(text)
    split_text = _separate_punct(split_text)
    return split_text
end

function get_kgrams(textlist::TextList, k::Int)::Dict
    
end

end
