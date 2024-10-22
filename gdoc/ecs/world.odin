package ecs

import "core:container/queue"


EntityId :: uint


World :: struct {
    entity_ids : queue.Queue(EntityId),
    max_entities : uint
}


/// Initialises the world
world_init :: proc(world : ^World, max_entities : uint) {
    queue.clear(&world.entity_ids)
    world.max_entities = max_entities
    queue.init(&world.entity_ids, int(world.max_entities))
    for x in 0..<world.max_entities do queue.push(&world.entity_ids, x)
}

world_destroy :: proc(world : ^World) {
    queue.destroy(&world.entity_ids)
}