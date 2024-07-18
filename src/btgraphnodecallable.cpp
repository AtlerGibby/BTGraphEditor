#include "btgraphnodecallable.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void BTGraphNodeCallable::_bind_methods() {

	ClassDB::bind_method(D_METHOD("called"), &BTGraphNodeCallable::called);
}

BTGraphNodeCallable::BTGraphNodeCallable() {
	// Initialize any variables here.
}

BTGraphNodeCallable::~BTGraphNodeCallable() {
	// Add your cleanup here.
}

void BTGraphNodeCallable::called(){
	(*wait)[0] = false;
}