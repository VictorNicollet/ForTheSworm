type 'a t = ('a,exn) BatStd.result option ref

let make () = ref None

let get r = !r

let set r a = r := Some a
