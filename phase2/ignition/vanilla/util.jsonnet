{
  build_params(arr):: std.flattenArrays(std.filter(function(a) a != null, arr)),

  // encode using the "data" URL scheme
  // https://tools.ietf.org/html/rfc2397
  encode_data(obj)::
    "data:;base64," + std.base64(std.manifestJson(obj)),
}
