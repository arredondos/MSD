import std.stdio;
import std.process;
import std.range;
import std.range.interfaces;
import std.algorithm.iteration;
import std.algorithm.comparison;
import std.algorithm.searching;
import std.conv;
import std.string;
import std.math;

void main(string[] argv) {
    write("How many T2 values do you long for in your heart? ");
	int count = to!int(strip(readln()));
	if(count <= 0) return;

	// generate ms stream
	auto islands = ["-I", "10", "2", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1"];
	auto ms = pipeProcess(["ms", "2", to!string(count), "-L"] ~ islands, Redirect.stdout);
	scope(exit) 
		wait(ms.pid);

	auto chunks = ms.stdout.byLine.drop(3).chunks(3);
	auto nums = chunks.map!(chunk => chunk.drop(1).front.splitter('\t').drop(1).front.to!double);

	// debugging
	auto debugNums = nums.array;

	// generate histogram
	const intervals = 64;
	auto extremes = [1e-3, 1e2]; //reduce!(min, max)(nums.save);
	auto timeVector = GetLogTimeVector(extremes[0], extremes[1], intervals);
	auto histogram = GetHistogram(assumeSorted(timeVector), debugNums);

	// generate F (distribution), f (density) and the IICR	
	auto normalizedHist = new double[intervals];
	normalizedHist[] = histogram[] / debugNums.length;

	auto distrib = normalizedHist.cumulativeFold!"a + b".array;
	
	auto density = new double[intervals];
	density[] =  normalizedHist[] / (timeVector[1..$] - timeVector[0..$-1]);	

	auto iicr = new double[intervals];
	iicr[] = (1.0 - distrib[]) / density[];

	// write the output to a file
	auto rawfile = File("ms_out.txt", "w");
	foreach(x; debugNums) {
		rawfile.write(x);
		rawfile.write(',');
	}

	auto file = File("ms_out.nb", "w");

	file.write("time=List");
	file.write(timeVector[0..$-1]);
	file.writeln(";");

	file.write("hist=List");
	file.write(histogram);
	file.writeln(";");

	file.write("distrib=List");
	file.write(distrib);
	file.writeln(";");

	file.write("density=List");
	file.write(density);
	file.writeln(";");

	file.write("iicr=List");
	file.write(iicr);
	file.writeln(";");

	writeln("Done!");
	readln();                           
}

auto GetLogTimeVector(in double min, in double max, in int intervals) {
	auto x = new double[intervals + 1];
	x[0] = 0;
	x[1] = min;
	
	for(int i = 1; i < intervals - 2; i++) 
		x[i + 1] = min * exp((i * log(max/min)) / (intervals - 2));
	
	x[intervals - 1] = max;
	x[intervals] = double.infinity;
	
	return x;
}

auto GetHistogram(R1, R2)(R1 bins, R2 data) /*if(isInputRange!R)*/ {
	auto n_plus_one = bins.length;
	auto hist = new double[n_plus_one - 1];
	hist[] = 0.0;
	foreach(x; data) {
		auto i = countUntil!"a > b"(bins, x);
	    ++hist[i - 1];
	}
	return hist;
}

//
//InputRange!double GetT2Values(int count) {
//    
//    auto islands = ["-I", "10", "2", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1"];
//    auto ms = pipeProcess(["ms", "2", to!string(count), "-T", "-L"] ~ islands, Redirect.stdout);
//
//    scope(exit) 
//        wait(ms.pid);
//
//    auto chunks = ms.stdout.byLine.drop(3).chunks(4);
//    auto nums = chunks.map!(chunk => chunk.drop(2).front.splitter('\t').drop(1).front.to!double);
//
//    return inputRangeObject(nums);
//}