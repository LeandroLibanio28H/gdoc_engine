package sparse_set

import "base:intrinsics"



SparseSetElement :: struct {
    _id : uint
}

/// Sparse Set base structure
SparseSet :: struct($T : typeid, $N : uint)
where
intrinsics.type_is_subtype_of(T, SparseSetElement) {
    dense : [N]T,
    sparse : [N]uint,
    count : uint
}


/// Checks if the sparse set contains an item where (item._id == idx)
sset_contains :: proc(idx : uint, sset : ^SparseSet($T, $N)) -> bool 
where 
intrinsics.type_is_subtype_of(T, SparseSetElement),
type_of(N) == uint {
    if idx >= len(sset.sparse) do return false
    return sset.sparse[idx] >= 0 && sset.sparse[idx] < sset.count && sset.dense[sset.sparse[idx]]._id == idx;
}

/// Returns (item, true) where (item._id == idx) if exists, otherwise, returns ({}, false)
sset_get :: proc(idx : uint, sset : ^SparseSet($T, $N)) -> (^T, bool) 
where 
intrinsics.type_is_subtype_of(T, SparseSetElement),
type_of(N) == uint {
    if !sset_contains(idx, sset) do return {}, false
    return &sset.dense[sset.sparse[idx]], true
}

/// Inserts the item to sparse set (index is defined by item._id)
sset_insert :: proc(element : $T, sset : ^SparseSet(T, $N)) 
where 
intrinsics.type_is_subtype_of(T, SparseSetElement),
type_of(N) == uint {
    if sset_contains(element._id, sset) do return
    sset.dense[sset.count] = element
    sset.sparse[element._id] = sset.count
    sset.count += 1
}

/// Deletes the item  where (item._id == idx) if exists
sset_delete :: proc(idx : uint, sset : ^SparseSet($T, $N))
where 
intrinsics.type_is_subtype_of(T, SparseSetElement),
type_of(N) == uint {
    if !sset_contains(idx, sset) do return
    sset.dense[sset.sparse[idx]] = sset.dense[sset.count - 1]
    sset.sparse[sset.dense[sset.count - 1]._id] = sset.sparse[idx]
    sset.count -= 1
}

/// Clears the sparse set
sset_clear :: proc(sset : ^SparseSet($T, $N)) 
where 
intrinsics.type_is_subtype_of(T, SparseSetElement){
    sset.count = 0
}

// Returns all item._id on the sparse set
sset_get_ids :: proc(sset : ^SparseSet($T, $N)) -> [dynamic]uint
where 
intrinsics.type_is_subtype_of(T, SparseSetElement),
type_of(N) == uint {
    result := make([dynamic]uint, 0, N)

    for i in 0..<sset.count {
        append(&result, sset.dense[i]._id)
    }
    return result
}