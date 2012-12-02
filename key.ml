type t = string

let of_bytes = BatPervasives.identity
let to_bytes = BatPervasives.identity
let of_sha1 = Sha1.to_bin

let bytes = 20
let hex = "0123456789ABCDEF"

let to_hex t = 
  let out = String.create (bytes * 2) in
  for i = 0 to bytes - 1 do 
    let c = Char.code t.[i] in
    out.[2*i  ] <- hex.[ c lsr  4  ] ;
    out.[2*i+1] <- hex.[ c land 31 ]
  done ;
  out

let to_hex_short k = 
  let hex = to_hex k in 
  String.sub hex 0 4 ^ ".." ^ String.sub hex 35 4
