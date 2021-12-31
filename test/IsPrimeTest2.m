classdef IsPrimeTest2 < matlab.unittest.TestCase
    % Additional regression and performance tests for isprime_fast.
    % These are slower than the tests in IsPrimeTest.m
    methods (Test)
        function smallScalars(testCase)
            max = 1000000;
            out = false(1, max);
            for x = 1:max
                out(x) = isprime_fast(x);
            end
            testCase.assertEqual(out, isprime(1:x));
        end

        function smallVector(testCase)
            range = 1:2:1700000;
            testCase.assertEqual(isprime_fast(range), isprime(range));
        end

        function mediumPrime(testCase)
            % medium prime is between 2^39 and 2^49
            max = 2000;
            out = false(1, max);
            N = randi([2^39, 2^49], [1, max]);
            evenIdx = mod(N, 2) == 0;
            N(evenIdx) = N(evenIdx) + 1;
            for x = 1:numel(N)
                out(x) = isprime_fast(N(x));
            end
            testCase.assertEqual(out, isprime(sym(N)), "Failed for: " + N);
            % 30 seconds
        end

        function Int64Array(testCase)
            % array near flintmax (9e15)
            upperRange = uint64(flintmax) + uint64(1:2:39);
            lowerRange = uint64(11:2:49);
            range = [upperRange; lowerRange];
            range = range(:);
            testCase.assertEqual(isprime(range), isprime_fast(range));
        end

        function Int64Array2(testCase)
            % max around 1.9e16
            range = [uint64(flintmax) + 11, nextprime(uint64(1.9e16))];
            testCase.assertEqual(isprime(range), isprime_fast(range));
        end

        function Int64Array3(testCase)
            upperRange = uint64(1.9e16) + uint64(1:2:19);
            lowerRange = uint64(11:2:29);
            range = [upperRange; lowerRange];
            range = range(:);
            testCase.assertEqual(isprime(range), isprime_fast(range));
        end

        function randInt64(testCase)
            % generate a random 64-bit int
            num = uint64(inf);
            for x = 1:randi(1000)
                num = num - randi(2^53 - 1);
            end
            if mod(num, 2) == 0
                num = num + 1;
            end
            % create a sequence of odd numbers
            range = num : 2 : num + 2000;
            testCase.assertTrue(all(mod(range, 2) == 1));

            % verify isprime_fast returns correct answer
            testCase.assertEqual(isprime_fast(range), isprime(sym(range)), ...
                "Failed for: " + num);
        end

        function perfSparse(testCase)
            s = sparse(500, 500);
            s(end) = prevprime(flintmax);
            expPerfGain = 2.84;
            measureArrayPerf(testCase, s, expPerfGain, 2);
        end

        function perfArrayE16(testCase)
            np = nextprime(uint64(7.2e16));
            range = [np, 1, np, 2, uint64(7.2e16) + 1, 3];
            expPerfGain = 15.8; % was 10.2;
            measureArrayPerf(testCase, range, expPerfGain, 2);
            % 4 seconds
        end

        function perfArrayE18(testCase)
            seq = [uint64(1e14), uint64(2e15), uint64(3e16), uint64(4e17), uint64(5e18), uint64(6e18)];
            range = repmat(nextprime(seq), [5, 1]);
            range = [range; range + 2];
            expPerfGainOverSym = .31; % sym wins
            measureSymPerf(testCase, range, expPerfGainOverSym);
        end

        function perfArrayE19(testCase)
            range = [nextprime(uint64(2e19)), nextprime(uint64(2e18)), nextprime(uint64(3e17)), uint64(flintmax*2)+1];
            expPerfGain = 190;
            measureArrayPerf(testCase, range, expPerfGain);
            % 35 seconds
        end

        function allButOneTinyNumber(testCase)
            range = [repelem(1, 10000000), uint64(4.7e18)];
            expPerfGain = 36.5;
            measureArrayPerf(testCase, range, expPerfGain);
            % 38 seconds
        end

        function longerArrayOfFlintmax(testCase)
            num = nextprime(uint64(flintmax));
            range = repelem(num, 300);
            expPerfGain = 1.88; % was 1.5;
            measureArrayPerf(testCase, range, expPerfGain);
            % original baseline before ModMultiply changes: 1x
            % len 300:   2.1x (34 sec)
            % len 1000:  ?? 1.57x (118 sec)
            % len 10000: ?? 1.35x (1185 sec)
        end

        function longerArrayE19(testCase)
            len = 25;
            range = zeros(1, len, "uint64");
            range(1) = prevprime(uint64(2e19));
            for x = 2:len
                range(x) = prevprime(range(x-1) - 1);
            end
            expPerfGain = 19.2;
            measureArrayPerf(testCase, range, expPerfGain);
            % len 25:  20x   (82 sec)
            % len 100: 15.5x (221 sec)
            % len 400: todo 12.6x (814 sec)
        end

        function perfShortSequence(testCase)
            % short sequence of highest uint64
            len = 12;
            range = uint64(inf) : -1 : uint64(inf) - len;
            expPerfGain = 960;
            measureArrayPerf(testCase, range, expPerfGain);
            % len 12:  960x  (53 sec)
            % len 100: 213x (213 sec)
            % len 500: todo:
        end

        function perfLongerSequence(testCase)
            % longer sequence of highest uint64
            % compare with isprime(symbolic) as isprime(num) is too slow
            range = uint64(inf) : -1 : uint64(inf) - 1200;
            expPerfGainOverSym = .094; % sym wins
            measureSymPerf(testCase, range, expPerfGainOverSym);
            % 10 seconds
        end

        function ismemberPathNearThreshold(testCase)
            % ismember path near threshold
            range = randi([7e8, 7.5e8], 1, 1300000);
            evenIdx = mod(range, 2) == 0;
        	range(evenIdx) = range(evenIdx) + 1;
            expPerfGain = 17.8;
            measureArrayPerf(testCase, range, expPerfGain, 1);
            % 100 seconds
        end

        function exception(testCase)
            % this function induces the try/catch in isprime_fast,
            % however it takes a very long time to run
            input = repelem(flintmax/262144 + 5, 100000000);
            %isprime_fast(input);
        end

        function roughlyEven(~)
            % compares sqrt(N) with N + ismember
            % todo: max > 1e8
            % [1]
            % range = randi(1e8, 1, 350000);
            % time: .63, max: 1e8, numel: 350000

            % [2]
            % range = randi([9.99e7, 1e8], 1, 370000);
            % time: .57, max: 1e8, numel: 370000

            % [3]
            % range = abs(floor(normrnd(1e8,1e7,[1,450000])));
            % time: .81, max 1.45e8, numel: 450000

            % [4, odd numbers -- might be more representative]
            % range = randi(1e8, 1, 177000);
            % evenIdx = mod(range, 2) == 0;
            % range(evenIdx) = range(evenIdx) + 1;
            % time: .61, max: 1e8, numel: 177000
        end
        
        function scalarCutoffPerf(~)
            % same cutoffs on pc1, pc2, linux, and mac
            % tic; isprime(nextprime(uint64(1.15e18))); toc
            % doubles from  15 ->  30 seconds at 4.6e18:  2^62
            % doubles from   7 ->  15 seconds at 1.15e18: 2^60
            % doubles from 3.5 ->   7 seconds at 2.88e17: 2^58
            % doubles from 1.8 -> 3.5 seconds at 7.2e16:  2^56
            % doubles from  .9 -> 1.8 seconds at 1.8e16:  2^54
        end

        function isPrimeLarge(~)
            % probably need to assume best case scenario which is all small other numbers
            % profile on; isprime(num); profile viewer;
            % 7e-7 seconds per iteration
            % isprime:     totalTime = cutOff + numel * 7e-7 = 31 + 7 = 38 sec
            % MillerRabin: totalTime = ones + MR(4.7e18) = .8 + .13 = 1 sec

            num = [repelem(1, 10000000), uint64(4.7e18)];
            % 31 sec primes, 7 sec loop
            
            num = [repelem(1, 1000), uint64(1.15e18)];
            % 7 sec primes, .51 sec loop
            num = [repelem(1, 10000000), uint64(1.15e18)];
            % 7 sec primes, 7 sec loop
            num = [1:1000, uint64(1.15e18)];
            % 7 sec primes, 37 sec loop

            num = [repelem(1, 5000), uint64(7.2e16)];
            % 1.8 sec primes, .13 sec loop
            num = [repelem(1, 10000000), uint64(7.2e16)];
            % 1.8 sec primes, 6 sec loop
            num = [repelem(1, 100000000), uint64(7.2e16)];
            % 1.8 sec primes, 63 sec loop

            num = [repelem(uint64(1.8e16), 1000)];
            % .9 sec primes, 71 sec loop
            %tic; arrayfun(@(n) isprime_fast(n), num); toc
            % Elapsed time is 17.337757 seconds.
        end

        function isPrimeFastLarge(testCase)
            % timeit(@() isprime_fast(num))
            num = nextprime(uint64(1e12));
            % 0.0032

            num = nextprime(uint64(1e13));
            % 0.0083

            num = nextprime(uint64(1e14));
            % 0.0250

            num = nextprime(uint64(1e15));
            % 0.0635

            num = nextprime(uint64(1e16));
            % 0.1019

            num = nextprime(uint64(1e17));
            % 0.1115

            num = prevprime(uint64(1e18));
            % 0.1285

            num = prevprime(uint64(1e19));
            % 0.1357

            num = prevprime(uint64(2e19));
            % 0.1900
        end
    end
end

function t2 = measureArrayPerf(testCase, range, expPerfGain, numTrials)
    arguments
        testCase;
        range;
        expPerfGain;
        numTrials = 1;
    end

    [t1, t2] = measureIt(range, numTrials);
    testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));

    if t1/t2 < expPerfGain
        disp 'Retrying with twice as many trials...'
        numTrials = numTrials * 2;
        [t1, t2] = measureIt(range, numTrials);
        testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
    end

    testCase.verifyGreaterThan(t1/t2, expPerfGain);

    % return average performance if isprime_fast
    t2 = t2 / numTrials;
end

function [t1, t2] = measureIt(range, numTrials)
    tic;
    for x = 1:numTrials
        isprime(range);
    end
    t1 = toc;

    tic;
    for x = 1:numTrials
        isprime_fast(range);
    end
    t2 = toc;
end

function t2 = measureSymPerf(testCase, range, expPerfGain, numTrials)
    arguments
        testCase;
        range;
        expPerfGain;
        numTrials = 1;
    end

    [t1, t2] = measureSym(range, numTrials);
    testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));

    if t1/t2 < expPerfGain
        disp 'Retrying with twice as many trials...'
        numTrials = numTrials * 2;
        [t1, t2] = measureSym(range, numTrials);
        testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
    end

    testCase.verifyGreaterThan(t1/t2, expPerfGain);

    % return average performance if isprime_fast
    t2 = t2 / numTrials;
end

function [t1, t2] = measureSym(range, numTrials)
    sRange = sym(range);
    tic;
    for x = 1:numTrials * 2
        isprime(sRange); % double trials then div 2 as sym is faster
    end
    t1 = toc;
    t1 = t1/2;
    
    tic;
    for x = 1:numTrials
        isprime_fast(range);
    end
    t2 = toc;
end
