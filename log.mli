type level = ERROR | WARNING | AUDIT | DEBUG 

val maxlevel : level ref

val out : level -> ('a, unit, string, unit) format4 -> 'a


