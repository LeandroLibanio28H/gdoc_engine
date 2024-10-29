package quadtree

import "core:container/queue"
import "core:fmt"

import "../../ecs"
import sset "../sparse_set"


/*
[Quadrant1, Quadrant2]
[Quadrant3, Quadrant4]
*/
QuadTreeQuadrant :: enum {
    Quadrant1,
    Quadrant2,
    Quadrant3,
    Quadrant4
}


Rect :: struct {
    x, y, width, height : i32
}


QuadTreeEntitiy :: struct {
    rect : Rect,
    using base : sset.SparseSetElement
}


QuadTreeNode :: struct {
    rect : Rect,
    level : i32,
    split : bool,
    entities : [dynamic]uint,
    quadrants : [QuadTreeQuadrant]^QuadTreeNode
}


QuadTree :: struct($N : uint) {
    max_entities_per_quadrant : i32,
    max_quadrant_level : i32,
    root : ^QuadTreeNode,
    nodes : queue.Queue(^QuadTreeNode),
    entities_sset : sset.SparseSet(QuadTreeEntitiy, N)
}


qtree_new :: proc(max_entities_per_quadrant : i32, max_quadrant_level : i32, rect : Rect, $N : uint) -> ^QuadTree(N) {
    result := new(QuadTree(N))
    result.max_quadrant_level = max_quadrant_level
    result.max_entities_per_quadrant = max_entities_per_quadrant
    result.root = qnode_new(max_entities_per_quadrant, 0, rect)
    return result
}


qnode_new :: proc(max_entities_per_quadrant : i32, level : i32, rect : Rect) -> ^QuadTreeNode {
    result := new(QuadTreeNode)
    result.rect = rect
    result.level = level
    result.split = false
    result.entities = make([dynamic]uint, 0, max_entities_per_quadrant)
    result.quadrants[.Quadrant1] = nil
    result.quadrants[.Quadrant2] = nil
    result.quadrants[.Quadrant3] = nil
    result.quadrants[.Quadrant4] = nil
    return result
}


qnode_split :: proc(qnode : ^QuadTreeNode, qtree : ^QuadTree($N)) 
where
type_of(N) == uint {
    for quadrant, index in QuadTreeQuadrant {
        qnode.quadrants[quadrant] = qnode_split_new(qnode, qtree, quadrant)
    }
    qnode.split = true
}


qnode_split_new :: proc(qnode : ^QuadTreeNode, qtree : ^QuadTree($N), quadrant : QuadTreeQuadrant) -> ^QuadTreeNode
where
type_of(N) == uint {
    subw := qnode.rect.width / 2
    subh := qnode.rect.height / 2
    x := qnode.rect.x
    y := qnode.rect.y
    rect := qnode.rect

    switch quadrant {
        case .Quadrant1:
            rect = Rect{x, y, subw, subh}
        case .Quadrant2:
            rect = Rect{x + subw, y, subw, subh}
        case .Quadrant3:
            rect = Rect{x, y + subh, subw, subh}
        case .Quadrant4:
            rect = Rect{x + subw, y + subh, subw, subh}
    }

    if qtree.nodes.len > 0 {
        result := queue.pop_front(&qtree.nodes)
        qnode_set(result, qnode.level + 1, rect)
        return result
    }
    else
    {
        return qnode_new(qtree.max_entities_per_quadrant, qnode.level + 1, rect)
    }
}


qnode_clear :: proc(qnode : ^QuadTreeNode, qtree : ^QuadTree($N))
where
type_of(N) == uint {
    if qnode.split {
		for q in qnode.quadrants {
			qnode_clear(q, qtree)
		}
	}
    qnode.rect = {}
    qnode.split = false
    clear(&qnode.entities)

    // Maybe?
    // qnode.quadrants[.Quadrant1] = nil
    // qnode.quadrants[.Quadrant2] = nil
    // qnode.quadrants[.Quadrant3] = nil
    // qnode.quadrants[.Quadrant4] = nil

    queue.push(&qtree.nodes, qnode)
}


qtree_root_clear :: proc(qtree : ^QuadTree($N))
where
type_of(N) == uint {
    if qtree.root.split {
		for q in qtree.root.quadrants {
			qnode_clear(q, qtree)
		}
	}
    qtree.root.split = false
    clear(&qtree.root.entities)
    sset.sset_clear(&qtree.entities_sset)
}


qnode_set :: proc(qnode : ^QuadTreeNode, level : i32, rect : Rect) {
    qnode.rect = rect
    qnode.level = level
    qnode.split = false
}


qnode_add_entity :: proc(qnode : ^QuadTreeNode, qtree : ^QuadTree($N), entity : uint, rect : Rect)
where
type_of(N) == uint {
    append(&qnode.entities, entity)
    sset.sset_insert(QuadTreeEntitiy{_id = entity, rect = rect}, &qtree.entities_sset)
}


qnode_get_quadrants :: proc(qnode : ^QuadTreeNode, entity : ^QuadTreeEntitiy) -> [dynamic]QuadTreeQuadrant {
    result := make([dynamic]QuadTreeQuadrant, 0, 4)

    mx := qnode.rect.x + qnode.rect.width / 2
    my := qnode.rect.y + qnode.rect.height / 2

    top := entity.rect.y <= my
    bottom := entity.rect.y >= my
    left := entity.rect.x <= mx
    right := entity.rect.x >= mx

    if top {
        if left do append(&result, QuadTreeQuadrant.Quadrant1)
        if right do append(&result, QuadTreeQuadrant.Quadrant2)
    }

    if bottom {
        if left do append(&result, QuadTreeQuadrant.Quadrant3)
        if right do append(&result, QuadTreeQuadrant.Quadrant4)
    }

    return result
}


qnode_insert :: proc(qnode : ^QuadTreeNode, qtree : ^QuadTree($N), entity : uint, rect : Rect)
where
type_of(N) == uint {
    if ((len(qnode.entities) < int(qtree.max_entities_per_quadrant) && !qnode.split) || qnode.level >= qtree.max_quadrant_level) {
        qnode_add_entity(qnode, qtree, entity, rect)
        return
    }

    qnode_add_entity(qnode, qtree, entity, rect)
    if !qnode.split do qnode_split(qnode, qtree)

    for e in qnode.entities {
        entity_data, okdata := sset.sset_get(e, &qtree.entities_sset)
        if okdata {
            quadrants := qnode_get_quadrants(qnode, entity_data)
            defer delete(quadrants)
            for i in quadrants {
                qnode_insert(qnode.quadrants[i], qtree, entity_data._id, entity_data.rect)
            }
        }
    }

    clear(&qnode.entities)
}


qtree_insert :: proc(qtree : ^QuadTree($N), entity : uint, x : i32, y : i32) 
where
type_of(N) == uint {
    rect := Rect{x, y, 0, 0}
    qnode_insert(qtree.root, qtree, entity, rect)
}


qtree_destroy :: proc(qtree : ^QuadTree($N))
where
type_of(N) == uint {
    qnode_clear(qtree.root, qtree)
    for qtree.nodes.len > 0 {
        node := queue.pop_front(&qtree.nodes)
        delete(node.entities)
        free(node)
    }
    queue.destroy(&qtree.nodes)
    free(qtree)
}
