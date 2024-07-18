#ifndef BTGRAPHNPDECALLABLECPP_H
#define BTGRAPHNPDECALLABLECPP_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

class BTGraphNodeCallable : public Object {
	GDCLASS(BTGraphNodeCallable, Object)

private:

protected:
	static void _bind_methods();

public:
	BTGraphNodeCallable();
	~BTGraphNodeCallable();

	// The "State" of this BTGraphNodeCallable
	Array * wait;

	// sets wait[0] to false
	void called();

	// Callable to called()
	Callable myCall;

};

}

#endif