package gdoctest

import "vendor:raylib"
import "core:fmt"
import "core:mem"
import "core:math/rand"

import "gdoc/ecs"


MAX_ENTITIES : ecs.EntityId : 5000

PositionComponent :: struct {
    x : f32,
    y : f32,
    using base : ecs.ComponentBase
}

VelocityComponent :: struct {
    x : f32,
    y : f32,
    using base : ecs.ComponentBase
}

DrawableComponent :: struct {using base : ecs.ComponentBase}

CollisionComponent :: struct {using base : ecs.ComponentBase}


GDOCTestWorld :: struct {
    position_components : ecs.ComponentContainer(PositionComponent, MAX_ENTITIES),
    velocity_components : ecs.ComponentContainer(VelocityComponent, MAX_ENTITIES),
    drawable_components : ecs.ComponentContainer(DrawableComponent, MAX_ENTITIES),
    collision_components : ecs.ComponentContainer(CollisionComponent, MAX_ENTITIES),
    using base : ecs.World
}


main :: proc() {
    when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

    world := GDOCTestWorld {}
    defer ecs.world_destroy(&world)
    ecs.world_init(&world, MAX_ENTITIES)

	for i in 0..<100 {
		entity := ecs.create_entity(&world)
		position := PositionComponent {
            x = f32(rand.int31() % 1280),
			y = f32(rand.int31() % 720)
		}
		velocity := VelocityComponent {
            x = rand.float32() * (10 if rand.int31() % 2 == 0 else -10),
			y = rand.float32() * (10 if rand.int31() % 2 == 0 else -10)
		}
		drawable := DrawableComponent {}
		collision := CollisionComponent {}
        
        
        ecs.add_component(entity, position, &world.position_components)
		ecs.add_component(entity, velocity, &world.velocity_components)
		ecs.add_component(entity, drawable, &world.drawable_components)
		ecs.add_component(entity, collision, &world.collision_components)
	}

	raylib.InitWindow(1280, 720, "GDOC TEST")
	raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(raylib.GetCurrentMonitor()))

	for !raylib.WindowShouldClose() {
		movement_system(&world)

		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.BLACK)

		draw_system(&world)

		raylib.DrawFPS(0, 0)

		raylib.EndDrawing()
	}
}


movement_system :: proc(world : ^GDOCTestWorld) {
	entities := ecs.get_entities_with_component(&world.position_components)
	defer delete(entities)

	query : for i in entities {
		position := ecs.get_component(i, &world.position_components) or_continue query
		velocity := ecs.get_component(i, &world.velocity_components) or_continue query
		
		position.x += velocity.x
		position.y += velocity.y

		if position.x > 1280 || position.x < 0 do velocity.x = -velocity.x
		if position.y > 720 || position.y < 0 do velocity.y = -velocity.y
	}
}

draw_system :: proc(world : ^GDOCTestWorld) {
	entities := ecs.get_entities_with_component(&world.position_components)
	defer delete(entities)

	query : for i in entities {
		position := ecs.get_component(i, &world.position_components) or_continue query
		drawable := ecs.get_component(i, &world.drawable_components) or_continue query
		
		raylib.DrawCircle(i32(position.x), i32(position.y), 10.0, raylib.WHITE)
	}
}