val endpoint : Protocol_types.endpoint
  
val send : Protocol_clientKernel.t -> stream:Key.t -> start:int -> count:int -> Key.t list option Protocol_response.t
