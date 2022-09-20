/*
* Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
* Copyright (C) 2022-present The WebF authors. All rights reserved.
*/

#include "parent_node.h"
#include "element_traversal.h"

namespace webf {

Element* ParentNode::firstElementChild(ContainerNode& node) {
  return ElementTraversal::FirstChild(node);
}

Element* ParentNode::lastElementChild(ContainerNode& node) {
  return ElementTraversal ::LastChild(node);
}

std::vector<Element*> ParentNode::children(ContainerNode& node) {
  return node.Children();
}

}