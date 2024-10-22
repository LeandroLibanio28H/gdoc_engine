package ecs

import "core:container/queue"
import "base:intrinsics"
import sset "../collections/sparse_set"


// Creates a new entity using the longest time available id
create_entity :: proc(world : ^World) -> EntityId {
    result := queue.pop_front(&world.entity_ids)
    return result
}

// Destroys the entity TODO: implement
destroy_entity :: proc(entity : EntityId) {

}

// Adds a component to given entity
add_component :: proc(entity : EntityId, component : $T, component_container : ^ComponentContainer(T, $N)) 
where
intrinsics.type_is_subtype_of(T, sset.SparseSetElement),
type_of(N) == EntityId {
    component := component
    component._id = entity
    sset.sset_insert(component, component_container)
}

// Returns (component, true) if entity has the component type, otherwise, returns ({}, false)
get_component :: proc(entity : EntityId, component_container : ^ComponentContainer($T, $N)) -> (^T, bool)
where
intrinsics.type_is_subtype_of(T, sset.SparseSetElement),
type_of(N) == EntityId {
    return sset.sset_get(entity, component_container)
}

// Returns a list of entity ids present on the given component container (Sparse set)
get_entities_with_component :: proc(component_container : ^ComponentContainer($T, $N)) -> [dynamic]uint
where
intrinsics.type_is_subtype_of(T, sset.SparseSetElement),
type_of(N) == EntityId {
    return sset.sset_get_ids(component_container)
}