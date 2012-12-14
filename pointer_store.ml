include Pointer_store_common
module Raw = Pointer_store_raw

let exists store key = 
  Store.find store key

