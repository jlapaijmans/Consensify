//============================================================================
// Name        : consensify_c.cpp
// Author      : Andrea Manica, Johanna Paijmans, Axel Barlow
// Version     : 2.2
// Copyright   : Your copyright notice
// Description : A general, C-based implementation of the Consensify algorithm
//============================================================================


#include <iostream>
#include <vector>
#include <fstream>
#include <sstream>
#include <random>
#include <algorithm>
using namespace std;

// from https://stackoverflow.com/questions/865668/parsing-command-line-arguments-in-c
// this avoids non-standard dependencies, as we just need to parse a couple of simple arguments
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
  bool allValidOptions() const{
    for (int i=0;i<this->tokens.size();i++){
      std::string i_token = this->tokens[i];
      if (std::find(this->validOptions.begin(), this->validOptions.end(), i_token) == this->validOptions.end()) {
        std::cerr << "The option "<<i_token<<" is not valid; use -h to get a list of all valid options"<<std::endl;
        return false;
    }
    // if this option takes an argument, skip it and move to the next option
    if (std::find(this->validOptionsWithArgument.begin(), this->validOptionsWithArgument.end(), i_token) != this->validOptionsWithArgument.end()) {
      i++;
    }
}
return true;}
    
private:
  std::vector <std::string> tokens;
  // set of valid options
  const std::vector <std::string> validOptions{"-p","-c","-s","-o","-min","-max","-n_matches","-n_random","-v","-no_empty_scaffold","-h"};
  // set of options that take an additional argument
  const std::vector <std::string> validOptionsWithArgument{"-p","-c","-s","-o","-min","-max","-n_matches","-n_random"};
};

// custom splitter for a file with one char field followed by 2 integer fields (as used in the position and scaffold file
void split_1char_2int(const std::string &s, char delim, std::string &chr_name, int &position, int &depth){
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

// custom splitter for a file with 4 integer fields (as used in the counts file)
void split_4int(const std::string &s, char delim, std::vector<int> &elems) {
  std::stringstream ss;
  ss.str(s);
  std::string item;
  for (int i=0;i<4;i++){
    std::getline(ss, item, delim);
    elems[i]= stoi(item);
  }
}

std::string trim( const std::string & s )
{
  auto first = s.find_first_not_of( " \f\n\r\t\v" );
  auto last  = s.find_last_not_of ( " \f\n\r\t\v" );
  return (first == s.npos) ? "" : s.substr( first, last+1 );
}


int main(int argc, char **argv){
  // defaults values
  int min_depth = 3;
  int max_depth = 100;
  int n_matches_to_call = 2;
  int n_random_reads = 3;
  bool verbose = false;
  bool empty_scaffold = true;
  
  
  // parse options
  cout << "welcome to consensify_c v2.2" << endl;
  InputParser input(argc, argv);
  
  if(input.cmdOptionExists("-h")){
    std::cout<<"Available options:\n";
    std::cout<<"\n";
    std::cout<<"-p filename(with path) of the positions file (required)\n";
    std::cout<<"-c filename(with path) of the counts file (required)\n";
    std::cout<<"-s filename(with path) of the scaffold file (required)\n";
    std::cout<<"-o filename(with path) of the output fasta (required\n";
    std::cout<<"-min minimum coverage for which positions should be called (defaults to 3)\n";
    std::cout<<"-max maximum coverage for which positions should be called (defaults to 100)\n";
    std::cout<<"-n_matches number of matches required to call a position (defaults to 2)\n";
    std::cout<<"-n_random_reads number of random reads used; note that fewer reads might be used if a position has depth<n_random_reads (defaults to 3)\n";
    std::cout<<"-v if set, verbose output to stout\n";
    std::cout<<"-no_empty_scaffold if set, empty scaffolds in the counts file are NOT printed in the fasta output\n";
    std::cout<<"-h a list of available options (note that other options will be ignored)\n";
    std::cout<<"\n";
    std::cout<<"example usage: consensify_c -c eg.counts -p eg.pos -o eg.fasta\n";
    std::cout<<"\n";
    exit(0);
  }
  // check that all options are valid
  if (!input.allValidOptions()){
  	exit(1);
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
    std::cout<<"a filename of counts should be defined with option -c"<<std::endl;
    exit(1);
  }
  const std::string &filename_scaffolds = input.getCmdOption("-s");
  if (filename_scaffolds.empty()){
    std::cout<<"a filename of scaffolds should be defined with option -s"<<std::endl;
    exit(1);
  }
  const std::string &filename_out = input.getCmdOption("-o");
  if (filename_out.empty()){
    std::cout<<"a filename for the FASTA output should be defined with option -o"<<std::endl;
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
  if(input.cmdOptionExists("-no_empty_scaffold")){
    empty_scaffold = false;
  }
  
  // dictionary vector
  vector<string> int_to_base{"A","C","G","T"};
  
  // random number generator
  std::random_device rd;
  std::mt19937 gen(rd());
  
  // ifstreams for counts and positions
  std::ifstream infile_counts (filename_counts);
  std::ifstream infile_pos (filename_positions);
  std::ifstream infile_scaffolds (filename_scaffolds);
  
  // ofstream to store info
  std::ofstream outfile_fasta (filename_out);
  
  std::string line_pos;
  std::string line_counts;
  std::string line_scaffolds;
  
  // check the headers
  std::getline(infile_counts, line_counts);
  if (line_counts!="totA	totC	totG	totT"){
    std::cout<<"header line for counts file should be :'totA	totC	totG	totT'"<<std::endl;
    std::cout<<"but we get '"<<line_counts<<"'\n";
    return 1;
  }
  std::getline(infile_pos, line_pos);
  if (line_pos!="chr	pos	totDepth"){
    std::cout<<"header line for positions file should be :'chr	pos	totDepth'"<<std::endl;
    std::cout<<"but we get '"<<line_pos<<"'\n";
    return 1;
  }
  std::getline(infile_scaffolds, line_scaffolds);
  if (line_scaffolds!="name	start	end"){
    std::cout<<"header line for scaffold file should be :'name	start	end'"<<std::endl;
    std::cout<<"but we get '"<<line_scaffolds<<"'\n";
    return 1;
  }
  
  // info to be parsed from the infiles
  std::string chr_name;
  std::string chr_name_current;
  int position=0;
  int position_previous;
  int depth;
  std::string chr_name_ref; // scaffold name in the scaffold file
  int start, end; // start and end of scaffold
  
  
  vector<int> counts(4);
  vector<int> sampled_reads(4);
  
  //split_1char_2int(line_scaffold, '\t', chr_name_ref, start, end);
  
  while (std::getline(infile_pos, line_pos))
  {
    position_previous=position;
    split_1char_2int(line_pos, '\t', chr_name, position, depth);
    if (verbose){
      std::cout<<chr_name<<"\t"<<position<<"\t"<<depth<<std::endl;
    }
    // set scaffold name if this is the first line, or if the scaffold has changed
    if (chr_name_current.empty() | (chr_name_current!=chr_name)){
      // if we were writing another scaffold, finish it and go to the next line
      if (!chr_name_current.empty() ){
        if (position_previous<end){
          for (int i=0;i<(end-position_previous);i++){
            outfile_fasta<<"N";
          }
        }
        outfile_fasta<<std::endl;
      } 
      chr_name_current = chr_name;
      position_previous = position -1;
    }
    

    // if the scaffold name differs from the current info from the scaffold file, get the next one
    while (chr_name!=chr_name_ref){
      std::getline(infile_scaffolds, line_scaffolds);
      // check that the last line is not an empty line
      if (trim(line_scaffolds).empty()){
        std::cout<<"ERROR: scaffold in the position file and scaffold file do not match (or are out of order)\n";
        std::cout<<"we failed to find "<<chr_name<<" as read in the positions file\n";
        exit(1);
        
      }
      split_1char_2int(line_scaffolds, '\t', chr_name_ref, start, end);
      // if it is still different
      if (chr_name!=chr_name_ref){
        // abort if are getting to the end of file
        if (infile_scaffolds.peek() == EOF){
          std::cout<<"ERROR: scaffold in the position file and scaffold file do not match (or are out of order)\n";
          std::cout<<"we failed to find "<<chr_name<<" as read in the positions file\n";
          exit(1);
        } else if (empty_scaffold){ //else we fill the contig with N if requested
          outfile_fasta<<">"<<chr_name_ref<<std::endl;
          for (int i=start;i<end+1;i++){
            outfile_fasta<<"N";
          }
          outfile_fasta<<"\n";
        }
      }
      // if we have found the correct scaffold
      if (chr_name==chr_name_ref) {
        outfile_fasta<<">"<<chr_name<<std::endl;
        if (position>start){ // if we have a new scaffold, but the first position in the pos file is not the same as the start of the scaffold, add some Ns
          for (int i=0;i<position-start;i++){
            outfile_fasta<<"N";
          }
        }
      }
    }
    
    // if we are only interested in a subset of the scaffold, ignore reads before or after it
    if (position<start | position>end){
      std::cout<<"ERROR: for scaffold "<<chr_name<<" we have reads at position "<<position;
      std::cout<<" which is outside the range given in the scaffold file\n";
      exit(1);
    }

    // if there are missing positions in the positions file, add them as Ns
    if (position!=(position_previous+1)){
      for (int i=0;i<(position-position_previous-1);i++){
        outfile_fasta<<"N";
      }
    }
        
    // read in the counts for this position
    std::getline(infile_counts, line_counts);
    // if the depth is below the minimum depth, then set this as missing value
    if ((depth>=min_depth) & (depth<=max_depth)){
      // sample randomly
      split_4int(line_counts, '\t', counts);
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
    } else { // set this as missing
      if (verbose){
        std::cout<<"Below minimum depth, set to N\n";
      }
      outfile_fasta<<"N";
    }
  }
  // check that on the very last scaffold, we don't have some missing values at the end
  if (position<end){
    for (int i=0;i<(end-position);i++){
      outfile_fasta<<"N";
    }
  }
  // now check that we don't have any empty scaffolds at the end of the scaffold file
  if (empty_scaffold){
    while (std::getline(infile_scaffolds, line_scaffolds)){
      // check that the last line is not an empty line
      if (trim(line_scaffolds).empty()){
        break;
      }
      split_1char_2int(line_scaffolds, '\t', chr_name_ref, start, end);      

    outfile_fasta<<"\n>"<<chr_name_ref<<std::endl;
    if (position>start){
      for (int i=0;i<position-start;i++){
        outfile_fasta<<"N";
      }
    }
    }
    
  }
  
  outfile_fasta<<std::endl;
  cout << "all done" << endl;
  return 0;
}
