//============================================================================
// Name        : consensify_c.cpp
// Author      : 
// Version     :
// Copyright   : Your copyright notice
// Description : Hello World in C++, Ansi-style
//============================================================================

// ~/eclipse-workspace/consensify_c/Debug/consensify_c -c eg.counts -p eg.pos -o eg.fasta

#include <iostream>
#include <vector>
#include <fstream>
#include <sstream>
#include <random>
#include <algorithm>
using namespace std;

// from https://stackoverflow.com/questions/865668/parsing-command-line-arguments-in-c
class InputParser{
    public:
        InputParser (int &argc, char **argv){
            for (int i=1; i < argc; ++i)
                this->tokens.push_back(std::string(argv[i]));
        }
        const std::string& getCmdOption(const std::string &option) const{
            std::vector<std::string>::const_iterator itr;
            itr =  std::find(this->tokens.begin(), this->tokens.end(), option);
            if (itr != this->tokens.end() && ++itr != this->tokens.end()){
                return *itr;
            }
            static const std::string empty_string("");
            return empty_string;
        }
        bool cmdOptionExists(const std::string &option) const{
            return std::find(this->tokens.begin(), this->tokens.end(), option)
                   != this->tokens.end();
        }
    private:
        std::vector <std::string> tokens;
};

void split_pos(const std::string &s, char delim, std::string &chr_name, int &position, int &depth){
    std::stringstream ss;
    ss.str(s);
    std::string item;
    std::getline(ss, item, delim);
    chr_name = item;
    std::getline(ss, item, delim);
    position = stoi(item);
    std::getline(ss, item, delim);
    depth = stoi(item);
}


void split_counts(const std::string &s, char delim, std::vector<int> &elems) {
    std::stringstream ss;
    ss.str(s);
    std::string item;
    for (int i=0;i<4;i++){
    	std::getline(ss, item, delim);
    	elems[i]= stoi(item);
    }
}


int main(int argc, char **argv){
	// defaults values
	int min_depth = 2;
	int max_depth = 100;
	int n_matches_to_call = 2;
	int n_random_reads = 3;
	bool verbose = false;


	// parse options
	cout << "welcome to consensify_c v2" << endl;
	InputParser input(argc, argv);
	if(input.cmdOptionExists("-h")){
	        std::cout<<"Available options:\n";
	        std::cout<<"\n";
	        std::cout<<"-p filename(with path) of the positions file (required)\n";
	        std::cout<<"-c filename(with path) of the counts file (required)\n";
	        std::cout<<"-o filename(with path) of the output fasta (required\n";
	        std::cout<<"-min minimum coverage for which positions should be called (defaults to 2)\n";
	        std::cout<<"-max maximum coverage for which positions should be called (defaults to 100)\n";
	        std::cout<<"-n_matches number of matches required to call a position (defaults to 2)\n";
	        std::cout<<"-n_random_reads number of random reads used (note that fewer reads might be used if a position has depth<n_random_reads (defaults to 3)\n";
	        std::cout<<"-v verbose output to stout\n";
	        std::cout<<"-h a list of available options (note that other options will be ignored)";
	        std::cout<<"\n";
	        std::cout<<"example usage: consensify_c -c eg.counts -p eg.pos -o eg.fasta\n";
	        exit(0);

	    }
	if(input.cmdOptionExists("-v")){
		verbose = true;
	}

	const std::string &filename_positions = input.getCmdOption("-p");
	if (filename_positions.empty()){
		std::cout<<"a filename of positions should be defined with option -p"<<std::endl;
		exit(1);
	}
	const std::string &filename_counts = input.getCmdOption("-c");
	if (filename_counts.empty()){
		std::cout<<"a filename of positions should be defined with option -c"<<std::endl;
		exit(1);
	}
	const std::string &filename_out = input.getCmdOption("-o");
	if (filename_out.empty()){
		std::cout<<"a filename of positions should be defined with option -o"<<std::endl;
		exit(1);
	}
	const std::string &min_depth_string = input.getCmdOption("-min");
	if (!min_depth_string.empty()){
		min_depth = stoi(min_depth_string);
	}
	const std::string &max_depth_string = input.getCmdOption("-max");
	if (!max_depth_string.empty()){
		max_depth = stoi(max_depth_string);
	}
	const std::string &n_matches_string = input.getCmdOption("-n_matches");
	if (!n_matches_string.empty()){
		n_matches_to_call = stoi(n_matches_string);
	}
	const std::string &n_random_reads_string = input.getCmdOption("-n_random_reads");
	if (!n_random_reads_string.empty()){
		n_random_reads = stoi(n_random_reads_string);
	}

	vector<string> int_to_base{"A","C","G","T"};

	// random number generator
	std::random_device rd;
	std::mt19937 gen(rd());

	// ifstreams for counts and positions
	std::cout<<filename_counts<<std::endl;
	std::ifstream infile_counts (filename_counts);
	std::ifstream infile_pos (filename_positions);
	// ofstream to store info
	std::ofstream outfile_fasta (filename_out);

	std::string line_pos;
	std::string line_counts;

	// check the headers
	std::getline(infile_counts, line_counts);
	if (line_counts!="totA	totC	totG	totT"){
		std::cout<<"header line for counts file should be :'totA	totC	totG	totT'"<<std::endl;
		return 1;
	}
	std::getline(infile_pos, line_pos);
	if (line_pos!="chr	pos	totDepth"){
		std::cout<<"header line for pos fiel sould be :'chr	pos	totDepth'"<<std::endl;
		return 1;
	}

	// info to be parsed from the infiles
	std::string chr_name;
	std::string chr_name_ref;
	int position;
	int depth;
	vector<int> counts(4);
	vector<int> sampled_reads(4);

    while (std::getline(infile_pos, line_pos))
    {
        split_pos(line_pos, '\t', chr_name, position, depth);
        if (verbose){
        	std::cout<<chr_name<<"\t"<<position<<"\t"<<depth<<std::endl;
        }
        // set chromosome name if this is the first line
        if (chr_name_ref.empty()){
        	chr_name_ref = chr_name;
        	outfile_fasta<<">"<<chr_name<<std::endl;
        } else if (chr_name_ref!=chr_name){
        	// write out the chromosome name
        	outfile_fasta<<std::endl;
        	outfile_fasta<<">"<<chr_name<<std::endl;
        	chr_name_ref = chr_name;
        }
         // read in the counts for this position
        std::getline(infile_counts, line_counts);
        // if the depth is below the minimum depth, then set this as missing value
        if ((depth>=min_depth) & (depth<=max_depth)){
        	// sample randomly
            split_counts(line_counts, '\t', counts);
            if (verbose) {
                    	std::cout<<"counts\tA "<<counts[0]<<"\tC "<<counts[1]<<"\tG "<<counts[2]<<"\tT "<<counts[3]<<std::endl;
            }
            	// sample random reads
            	std::fill(sampled_reads.begin(), sampled_reads.end(), 0);
            	int n_random_reads_this_pos=n_random_reads;
            	if (n_random_reads>depth){
            		n_random_reads_this_pos=depth;
            	}
            	for (int i=0;i<n_random_reads_this_pos;i++){
            		int read_counter = 3;
            		std::uniform_int_distribution<int> ui_distribution(0,depth-1-i);
                 	int random_index = ui_distribution(gen);
                	while(counts[read_counter]<= random_index){
                		random_index -= counts[read_counter];
                		--read_counter;
                	}
                	// update counts
                	counts[read_counter]--;
                	sampled_reads[read_counter]++;
                	//std::cout<<read_counter<<"\t";
            	}
                if (verbose) {
                         	std::cout<<"sampled\tA "<<sampled_reads[0]<<"\tC "<<sampled_reads[1]<<"\tG "<<sampled_reads[2]<<"\tT "<<sampled_reads[3]<<std::endl;

                }
            	// now check if we have a majority
            	for (int i=0;i<5;i++){
            		if (i==4){
            			outfile_fasta<<"N";
            			if (verbose){
            				std::cout<<"There is no majority, set as N\n";
            			}
            			break;
            		}
            		if (sampled_reads[i]>n_matches_to_call-1) {
            			//outfile_fasta<<convert_int_to_base(i);
            			outfile_fasta<<int_to_base[i];
            			if (verbose){
            				std::cout<<"Consensus is "<<int_to_base[i]<<"\n";
            			}
            			break;
            		}
            	}
            	//std::cout<<std::endl;
        } else { // set this as missing
        	if (verbose){
        	std::cout<<"Below minimum depth, set to N\n";
        	}
        	outfile_fasta<<"N";
       }
    }

    outfile_fasta<<std::endl;
    cout << "all done" << endl;
    return 0;
}
