val endpoint : Protocol_types.endpoint
  
val send : Protocol_clientKernel.t -> stream:Key.t -> events:Key.t list -> int Protocol_response.t
