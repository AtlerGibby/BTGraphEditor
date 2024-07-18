#include "btinterpretercpp.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void BTInterpreterCPP::_bind_methods() {

	ClassDB::bind_method(D_METHOD("execute_logic"), &BTInterpreterCPP::execute_logic);
	ClassDB::bind_method(D_METHOD("setup", "vars", "sigs", "acts", "wait_sigs", "current_nodes", "parent_node"), &BTInterpreterCPP::setup);
	ClassDB::bind_method(D_METHOD("setup_nodes", "pos", "names", "rids", "opt1", "opt2", "txt", "toNodes", "fromNodes", "toPorts", "fromPorts"), &BTInterpreterCPP::setup_nodes);
	ClassDB::bind_method(D_METHOD("edit_variable", "name", "value"), &BTInterpreterCPP::edit_variable);
	ClassDB::bind_method(D_METHOD("skip_all_current_nodes"), &BTInterpreterCPP::skip_all_current_nodes);
	ClassDB::bind_method(D_METHOD("skip_current_node", "which_node"), &BTInterpreterCPP::skip_current_node);
	ClassDB::bind_method(D_METHOD("stop_all_branches"), &BTInterpreterCPP::stop_all_branches);
	ClassDB::bind_method(D_METHOD("stop_a_branch", "which_branch"), &BTInterpreterCPP::stop_a_branch);

	ClassDB::bind_method(D_METHOD("get_current_node_rids"), &BTInterpreterCPP::get_currentNodeRids);
	ClassDB::bind_method(D_METHOD("set_current_node_rids", "val"), &BTInterpreterCPP::set_currentNodeRids);
	ClassDB::add_property("BTInterpreterCPP", PropertyInfo(Variant::PACKED_STRING_ARRAY, "current_node_rids"), "set_current_node_rids", "get_current_node_rids");

	ClassDB::bind_method(D_METHOD("get_random_seed"), &BTInterpreterCPP::get_randomSeed);
	ClassDB::bind_method(D_METHOD("set_random_seed", "val"), &BTInterpreterCPP::set_randomSeed);
	ClassDB::add_property("BTInterpreterCPP", PropertyInfo(Variant::INT, "random_seed"), "set_random_seed", "get_random_seed");
}

BTInterpreterCPP::BTInterpreterCPP() {
	// Initialize any variables here.
}

BTInterpreterCPP::~BTInterpreterCPP() {
	// Add your cleanup here.
	stop_all_branches();
	for (int i = 0; i < myBTNodes.size(); i++)
	{
		if (myBTNodes[i].wait != nullptr)
			delete(myBTNodes[i].wait);
		if (myBTNodes[i].waitCallable != nullptr)
			delete(myBTNodes[i].waitCallable);
	}
	

}

void BTInterpreterCPP::set_currentNodeRids(const PackedStringArray val) {
	currentNodeRids = val;
}

PackedStringArray BTInterpreterCPP::get_currentNodeRids() const {
	return currentNodeRids;
}

void BTInterpreterCPP::set_randomSeed(const int val){
	randomSeed = val;
}

int BTInterpreterCPP::get_randomSeed() const {
	return randomSeed;
}

void BTInterpreterCPP::setup(Dictionary vars, Array sigs, Array acts, Array waitSigs, Array cur, Node * parentNode) {
	variables = vars;
	for (int i = 0; i < sigs.size(); i++) {
		signals.push_back(String(sigs[i]));
	}
	for (int i = 0; i < acts.size(); i++) {
		actions.push_back(String(acts[i]));
	}
	for (int i = 0; i < waitSigs.size(); i++) {
		waitSignals.push_back(String(waitSigs[i]));
	}	
	gdInterpreter = parentNode;
	myParent = gdInterpreter->get_parent();
}


void BTInterpreterCPP::setup_nodes(PackedVector2Array pos, PackedStringArray names, PackedStringArray rids, PackedInt32Array opt1,
PackedInt32Array opt2, PackedStringArray txt, Array toNodes, Array fromNodes, Array toPorts, Array fromPorts)
{
	for (int i = 0; i < pos.size(); i++) {
		BTInterpreterCPP::BTGraphNode newNode = BTInterpreterCPP::BTGraphNode();
		newNode.name = names[i];
		newNode.pos = pos[i];
		newNode.rid = rids[i];
		newNode.opt1 = opt1[i];
		newNode.opt2 = opt2[i];
		newNode.txt = txt[i];
		newNode.toPorts = toPorts[i];
		newNode.fromPorts = fromPorts[i];
		newNode.index = i;
		myBTNodes.push_back(newNode);
	}

	for (int i = 0; i < myBTNodes.size(); i++) {
		PackedInt32Array pia = toNodes[i];
		for (int j = 0; j < pia.size(); j++) {
			myBTNodes[i].toNodes.insert(myBTNodes[i].toNodes.begin(), &myBTNodes[pia[j]]);
		}
		pia = fromNodes[i];
		for (int j = 0; j < pia.size(); j++) {
			myBTNodes[i].fromNodes.insert(myBTNodes[i].fromNodes.begin(), &myBTNodes[pia[j]]);
		}
	}
	
}

void BTInterpreterCPP::edit_variable(String name, Variant value)
{
	if (Variant::get_type_name(variables[name].get_type()) == "bool")
		variables[name] = bool(value);
	if (Variant::get_type_name(variables[name].get_type()) == "int")
		variables[name] = int(value);
	if (Variant::get_type_name(variables[name].get_type()) == "float")
		variables[name] = float(value);
}


// Stop all branches / reset behavior tree.
void BTInterpreterCPP::stop_all_branches(){
	skip_all_current_nodes();
	branches.clear();
	branches2.clear();
}

// Stop the current branch.
void BTInterpreterCPP:: BTInterpreterCPP::stop_a_branch(int whichBranch){
	skip_current_node(whichBranch);
	if (branches.size() > whichBranch)
		branches.erase(branches.begin() + whichBranch);
	branches2.remove_at(whichBranch);
}


// Skip all nodes that are waiting
void BTInterpreterCPP:: BTInterpreterCPP::skip_all_current_nodes(){
	for (int i = 0; i < currentNodeIndexes.size(); i++){
		skip_current_node(currentNodeIndexes[i]);
	}
}

// Skip the current node on a branch that is waiting
void BTInterpreterCPP::skip_current_node(int whichNode){
	if (currentNodeIndexes.size() > whichNode){
		myBTNodes[whichNode].isWaiting = false;
		if (myBTNodes[whichNode].wait != nullptr)
			delete(myBTNodes[whichNode].wait);
		myBTNodes[whichNode].wait = nullptr;
		if (myBTNodes[whichNode].sceneTreeTimer != nullptr)
			myBTNodes[whichNode].sceneTreeTimer.unref();
		if (myBTNodes[whichNode].waitCallable->myCall.is_null() == false){
			myParent->disconnect(waitSignals[myBTNodes[whichNode].opt1-2], myBTNodes[whichNode].waitCallable->myCall);
			myBTNodes[whichNode].waitCallable->myCall = Callable();
		}
		currentNodeIndexes.remove_at(whichNode);
		currentNodeRids.remove_at(whichNode);
	}
}

void BTInterpreterCPP::execute_logic() {

	// Set branches vector using branches2 array.
	if (branches.size() <= 0 && branches2.size() > 0){
		branches = std::vector<std::vector<BTInterpreterCPP::BTGraphNode*>>();
		for (int i = 0; i < branches2.size(); i++) {
			std::vector<BTInterpreterCPP::BTGraphNode*> currentBranch = std::vector<BTInterpreterCPP::BTGraphNode*>();
			TypedArray<int> cb = (TypedArray<int>)(branches2[i]);
			for (int j = 0; j < cb.size(); j++) {
				currentBranch.push_back(&myBTNodes[int32_t(cb[j])]);
			}
			branches.push_back(currentBranch);
		}

	}

	// When executing logic for the first time or after a reset. Initialize branches and branches2.
	if (branches.size() <= 0){
		branches = std::vector<std::vector<BTInterpreterCPP::BTGraphNode*>>();
		branches2 = Array();
		for (int i = 0; i < myBTNodes.size(); i++) {
			if (myBTNodes[i].name == "Root") {
				std::vector<BTInterpreterCPP::BTGraphNode*> currentBranch = std::vector<BTInterpreterCPP::BTGraphNode*>();
				TypedArray<int> cb = TypedArray<int>();
				for (int j = 0; j < myBTNodes[i].toNodes.size(); j++) {
					currentBranch.insert(currentBranch.begin(), myBTNodes[i].toNodes[j]);
					cb.insert(0, myBTNodes[i].toNodes[j]->index);
				}
				branches.push_back(currentBranch);
				branches2.append(cb);
				currentNodeRids.append(currentBranch[0]->rid);
				currentNodeIndexes.append(currentBranch[0]->index);
				break;
			}
		}
	}
	
	RandomNumberGenerator rng = RandomNumberGenerator();
	time_t now = time(0);
	struct tm * ptm;
	ptm = gmtime(&now);
	rng.set_seed(ptm->tm_year * ptm->tm_mday * ptm->tm_hour * ptm->tm_min * ptm->tm_sec * randomSeed);
	

	if (branches.size() > 0){

		for (int i = 0; i < branches.size(); i++){ //Each node in each parallel branch

			std::vector<BTInterpreterCPP::BTGraphNode*> potentialNewNodes = branches[i];
			if (potentialNewNodes.size() == 0){
				currentNodeRids.remove_at(i);
				currentNodeIndexes.remove_at(i);
				branches.erase(branches.begin() + i);
				branches2.remove_at(i);
				continue;
			}
			
			//UtilityFunctions::print("LOOP: " + potentialNewNodes[0]->name);

			BTInterpreterCPP::BTGraphNode * current = potentialNewNodes[0];
			currentNodeRids.insert(i, current->rid);
			currentNodeIndexes.insert(i, current->index);
			currentNodeRids.remove_at(i + 1);
			currentNodeIndexes.remove_at(i + 1);

			// Current node calls a function / action.
			if (current->name == "Action"){
				if (current->opt1 > 0){ //Action Selected
					if (current->opt2 > 0){ //Has Wait Behavior
						if (current->isWaiting == true){
							Array * bt_wait = current->wait;
							myParent->call((actions[current->opt1-1]).substr(8), (*bt_wait));
							if (current->opt2 == 1 && (bool((*bt_wait)[0])) == true)
								continue;
							if (current->opt2 == 2 && (bool((*bt_wait)[0])) == false)
								continue;
							current->isWaiting = false;

							if (current->wait != nullptr)
								delete(current->wait);
							current->wait = nullptr;
						}
						else{
							current->isWaiting = true;
							Array * bt_wait = new Array();
							current->wait = bt_wait;
							if (current->opt2 == 1)
								(Array(*bt_wait)).append(true);
							else
								(Array(*bt_wait)).append(false);
							myParent->call((actions[current->opt1-1]).substr(8), (*bt_wait));
							continue;
						}
					}
					else{
						myParent->call((actions[current->opt1-1]).substr(8), nullptr);
					}
				}
			}

			// Current node emits a signal.
			if (current->name == "Signal"){
				gdInterpreter->emit_signal(signals[current->opt1-1]);
			}

			// Current node creates a "SceneTreeTimer" and waits on it or waits on a signal from "MyParent".
			if (current->name == "Wait"){
				if (current->opt1 <= 1){ //Wait on time
					if (current->isWaiting == true)
					{
						if (current->sceneTreeTimer->get_time_left() > 0){
							continue;
						}
						else{
							current->isWaiting = false;
							current->sceneTreeTimer.unref();
						}
					}
					else{
						current->isWaiting = true;
						float waitTime = current->txt.to_float();
						if (waitTime > 0)
						{
							if (current->opt1 == 1)
								waitTime /= 1000;
							current->sceneTreeTimer = get_tree()->create_timer(waitTime);
							continue;
						}
					}
				}
				else{ //Wait on Signal
					if (current->isWaiting == true){
						Array * bt_wait = current->wait;
						if ((bool((*bt_wait)[0])) == true)
							continue;
						current->isWaiting = false;
						myParent->disconnect(waitSignals[current->opt1-2], current->waitCallable->myCall);
						current->waitCallable->myCall = Callable();

						if (current->wait != nullptr)
							delete(current->wait);
						current->wait = nullptr;
						if (current->waitCallable != nullptr)
							delete(current->waitCallable);
						current->waitCallable = nullptr;
					}
					else{
						current->isWaiting = true;
						Array * bt_wait = new Array();
						current->wait = bt_wait;
						Array(*bt_wait).append(true);

						if (current->waitCallable != nullptr)
							delete(current->waitCallable);
						
						BTGraphNodeCallable * callableFunc = new BTGraphNodeCallable();
						callableFunc->wait = bt_wait;
						current->waitCallable = callableFunc;
						current->waitCallable->myCall = callable_mp(current->waitCallable, &BTGraphNodeCallable::called);
						myParent->connect(waitSignals[current->opt1-2], current->waitCallable->myCall);
						continue;
					}
				}
			}

			// Update branches2
			if (current->name != "Sequencer" && current->name != "If"){
				TypedArray<int> cb = branches2[i];
				cb.remove_at(0);

				branches2[i].clear();
				branches2[i] = cb;
				potentialNewNodes.erase(potentialNewNodes.begin());
			}

			// Current node branches off based on the type of sequencer it is.
			if (current->name == "Sequencer"){
				TypedArray<int> cb = branches2[i];
				cb.remove_at(0);
				potentialNewNodes.erase(potentialNewNodes.begin());
				if (current->opt1 == 1){ //Parallel
					for (int j = 0; j < current->toNodes.size(); j++){//next in current->to_nodes:{
						std::vector<BTInterpreterCPP::BTGraphNode*> currentBranch = std::vector<BTInterpreterCPP::BTGraphNode*>();
						//current_branch.insert(0, next);

						TypedArray<int> cbparallel = TypedArray<int>();
						cbparallel.insert(0, current->toNodes[j]->index);
						branches2.append(cbparallel);

						currentBranch.insert(currentBranch.begin(), current->toNodes[j]);
						branches.push_back(currentBranch);
						currentNodeRids.append(current->rid);
						currentNodeIndexes.append(current->index);
					}
				}
				
				if (current->opt1 == 2){ //Random
					for (int j = 0; j < current->toNodes.size(); j++){// next in current->to_nodes:
						int ran = rng.randi_range(0, current->toNodes.size() - 1);
						bool caught = false;
						if (j > 0){
							ran = rng.randi_range(0, current->toNodes.size() - 1);
							while (caught == false){
								caught = true;
								for (int k = 0; k < cb.size(); k++){
									if (int(cb[k]) == current->toNodes[ran]->index){
										caught = false;
										break;
									}
								}
								if (caught)
									break;
								if (ran >= current->toNodes.size() - 1)
									ran = 0;
								else
									ran += 1;
							}
						}
						potentialNewNodes.push_back(current->toNodes[ran]);
						cb.push_back(current->toNodes[ran]->index);
					}
				}
				
				if (current->opt1 == 3){ //TotallyRandom
					for (int j = 0; j < current->toNodes.size(); j++){// next in current->to_nodes:
						int ran = rng.randi_range(0, current->toNodes.size() - 1);
						potentialNewNodes.push_back(current->toNodes[ran]);
						cb.push_back(current->toNodes[ran]->index);
					}
				}
				
				if (current->opt1 == 0){ //TopDown
					for (int j = 0; j < current->toNodes.size(); j++){// next in current->to_nodes:
						potentialNewNodes.push_back( current->toNodes[j]);
						cb.push_back(current->toNodes[j]->index);
					}
				}

				//cb.remove_at(cb.size() - 1);
				branches2[i].clear();
				branches2[i] = cb;
			}

			// Current node branches off based on a boolean input.
			if (current->name == "If"){
				BTInterpreterCPP::BTGraphNode * boolInput = nullptr;
				std::vector<BTInterpreterCPP::BTGraphNode*> * trueOutput = new std::vector<BTInterpreterCPP::BTGraphNode*>();
				std::vector<BTInterpreterCPP::BTGraphNode*> * falseOutput = new std::vector<BTInterpreterCPP::BTGraphNode*>();
				TypedArray<int> cb = branches2[i];
				cb.remove_at(0);
				potentialNewNodes.erase(potentialNewNodes.begin());

				for (int j = 0; j < current->toPorts.size(); j++){// x in range(len(current->to_ports)){
					if (current->toNodes[j]->fromPorts[0] == 0){
						trueOutput->push_back(current->toNodes[j]);
						}
					else{
						falseOutput->push_back(current->toNodes[j]);
					}
				}
				if (current->fromPorts.size() > 1){
					if (current->fromPorts[0] == 1)
						boolInput = current->fromNodes[0];
					else
						boolInput = current->fromNodes[1];

					int bool_val = evaluate_bool(boolInput, current);
					if (bool_val == 1){ //true
						for (int j = 0; j < trueOutput->size(); j++){// next in true_output:
							potentialNewNodes.push_back((*trueOutput)[j]);
							cb.push_back((*trueOutput)[j]->index);
						}
					}
					else{ //false
						for (int j = 0; j < falseOutput->size(); j++){// next in false_output:
							potentialNewNodes.push_back((*falseOutput)[j]);
							cb.push_back((*falseOutput)[j]->index);
						}
					}
				}
				else{ // Assume false if no input.
					for (int j = 0; j < falseOutput->size(); j++){// next in false_output:
						potentialNewNodes.push_back((*falseOutput)[j]);
						cb.push_back((*falseOutput)[j]->index);
					}
				}
				branches2[i].clear();
				branches2[i] = cb;
				delete(trueOutput);
				delete(falseOutput);
			}
		}
		branches.clear();
	}
	
}

float BTInterpreterCPP::evaluate_bool(BTInterpreterCPP::BTGraphNode * node, BTInterpreterCPP::BTGraphNode * fromNode)
{
	if (node == nullptr)
	{
		return 0;
	}
	
	if (node->name == "Variable")
	{
		if (node->opt1 == 0){ //true
			return 1;
		}
		if (node->opt1 == 1){ //false
			return 0;
		}
		if (node->opt1 == 2){ //int
			int txt_num = node->txt.to_int();
			return txt_num;
		}
		if (node->opt1 == 3){ //float
			float txt_num = node->txt.to_float();
			return txt_num;
		}
		if (node->opt1 >= 4){ //Variable from left panel
			Variant theVar = variables[variables.keys()[node->opt1-4]];
			if (theVar.get_type_name(theVar.get_type()) == "float" || theVar.get_type_name(theVar.get_type()) == "int")
			{
				return float(theVar);
			}
			if (theVar.get_type_name(theVar.get_type()) == "bool"){
				if (bool(theVar))
					return 1;
				else
					return 0;
			}
		}
	}
	else{ //Keep searching tree leftward
		BTInterpreterCPP::BTGraphNode * from_node_top = nullptr;
		BTInterpreterCPP::BTGraphNode * from_node_bottom = nullptr;
		
		if (node->fromPorts.size() > 0){
			if (node->fromPorts[0] == 0){
				from_node_top = node->fromNodes[0];
				if (node->fromNodes.size() > 1)
					from_node_bottom = node->fromNodes[1];
			}
			else{
				from_node_bottom = node->fromNodes[0];
				if (node->fromNodes.size() > 1)
					from_node_top = node->fromNodes[1];
			}
		}
		
		if (node->name == "Bool"){
			if (node->opt1 == 0) //AND
				return float(evaluate_bool(from_node_top, node) > 0 && evaluate_bool(from_node_bottom, node) > 0);
			if (node->opt1 == 1) //OR
				return float(evaluate_bool(from_node_top, node) > 0 || evaluate_bool(from_node_bottom, node) > 0);
			if (node->opt1 == 2) //NOT
				return float(evaluate_bool(from_node_top, node) <= 0);
			if (node->opt1 == 3) //XOR
				return float(!(evaluate_bool(from_node_top, node) == evaluate_bool(from_node_bottom, node)));
		}
		if (node->name == "Statement"){
			if (node->opt1 == 0) //GreaterThan
				return float(evaluate_bool(from_node_top, node) > evaluate_bool(from_node_bottom, node));
			if (node->opt1 == 1) //LessThan
				return float(evaluate_bool(from_node_top, node) < evaluate_bool(from_node_bottom, node));
			if (node->opt1 == 2) //EquallTo
				return float(evaluate_bool(from_node_top, node) == evaluate_bool(from_node_bottom, node));
		}
	}
	return 0;
}