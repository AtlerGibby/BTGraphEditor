#ifndef BTINTERPRETERCPP_H
#define BTINTERPRETERCPP_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/scene_tree_timer.hpp>
#include <godot_cpp/classes/random_number_generator.hpp>
#include "btgraphnodecallable.h"

namespace godot {

class BTInterpreterCPP : public Node {
	GDCLASS(BTInterpreterCPP, Node)

private:

protected:
	static void _bind_methods();

public:
	BTInterpreterCPP();
	~BTInterpreterCPP();

	void set_currentNodeRids(const PackedStringArray val);
	PackedStringArray get_currentNodeRids() const;

	void set_randomSeed(const int val);
	int get_randomSeed() const;

	void setup(Dictionary vars, Array sigs, Array acts, Array waitSigs, Array cur, Node * parentNode);

	void setup_nodes(PackedVector2Array pos, PackedStringArray names, PackedStringArray rids, 
	PackedInt32Array opt1, PackedInt32Array opt2, PackedStringArray txt, Array toNodes,
	Array fromNodes, Array toPorts, Array fromPorts);

	void edit_variable(String name, Variant value);
	void skip_all_current_nodes();
	void skip_current_node(int whichNode);
	void stop_all_branches();
	void stop_a_branch(int whichBranch);

	void execute_logic();

	// Temporary object for storing the info of a node in the BTGraph.
	class BTGraphNode {
		public:
			Vector2 pos;
			String name;
			String rid;
			int opt1;
			int opt2;
			String txt;
			std::vector<BTInterpreterCPP::BTGraphNode*> toNodes = std::vector<BTInterpreterCPP::BTGraphNode*>();
			std::vector<BTInterpreterCPP::BTGraphNode*> fromNodes = std::vector<BTInterpreterCPP::BTGraphNode*>();
			
			PackedInt32Array toNodesIs = PackedInt32Array();
			PackedInt32Array fromNodesIs = PackedInt32Array();
			PackedInt32Array toPorts = PackedInt32Array();
			PackedInt32Array fromPorts = PackedInt32Array();

			int index;
		
			bool isWaiting;
			Ref<SceneTreeTimer> sceneTreeTimer;
			Array * wait;
			BTGraphNodeCallable * waitCallable;

	};

	float evaluate_bool(BTInterpreterCPP::BTGraphNode * node, BTInterpreterCPP::BTGraphNode * from_node);

	// List of all branches. Stores "TypedArray<int>"s of myBTNodes indexes.
	Array branches2 = Array();
	// A temporary list of branches, doesn't get saved at the end of execute_logic().
	std::vector<std::vector<BTInterpreterCPP::BTGraphNode*>> branches = std::vector<std::vector<BTInterpreterCPP::BTGraphNode*>>();
	// List of all current node RIDs on all branches.
	PackedStringArray currentNodeRids = PackedStringArray();
	// List of all current node indexes on all branches.
	PackedInt32Array currentNodeIndexes = PackedInt32Array();

	// List of all nodes in the BTGraph.
	std::vector<BTInterpreterCPP::BTGraphNode> myBTNodes;

	Dictionary variables;
	std::vector<String> signals;
	std::vector<String> actions;
	std::vector<String> waitSignals;

	Node * myParent;
	Node * gdInterpreter;

	int randomSeed = 1;
	
};

}

#endif