type store = string

val save : store -> Key.t -> (out_channel -> unit) -> (unit, exn) BatStd.result Event.event
val load : store -> Key.t -> (in_channel -> 'a) ->  ('a option, exn) BatStd.result Event.event
val find : store -> Key.t -> (bool, exn) BatStd.result Event.event
