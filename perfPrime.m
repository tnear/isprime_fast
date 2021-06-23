classdef perfPrime < matlab.unittest.TestCase
    methods (Test)
        function [t1, t2, t3] = perfScalar(~)
            numBits = 24;
            checkPrime = true;
            % checkPrime = false: check odd numbers
            % checkPrime = true: check prime numbers (often worse-case)
            t1 = [];
            t2 = [];
            t3 = [];
            for idx = 1:50
                [x, y, z] = getPerf(numBits, checkPrime);
                t1 = [t1, x]; %#ok<AGROW>
                t2 = [t2, y]; %#ok<AGROW>
                t3 = [t3, z]; %#ok<AGROW>
            end
            t1 = mean(t1);
            t2 = mean(t2);
            t3 = mean(t3);
        end

        function incrementingSequence(~)
            arr = 1:10000000;
            % 139 seconds
            tic, isprime(arr); toc;

            tic, isprime_fast(arr); toc;
            % .660 seconds

            sArr = sym(arr);
            tic, isprime(sArr); toc; 
            % todo: time this
        end

        function int32Matrix(~)
            range = randi(intmax('int32'), [1000, 1000], 'int32');
            tic, isprime(range); toc
            % Elapsed time is 17.686067 seconds.
            tic, isprime_fast(range); toc
            % Elapsed time is 3.927214 seconds.

            sRange = sym(range);
            tic, isprime(sRange); toc
        end

        function oneHundredLargestPrimes(~)
            % 100 largest primes
            prime = zeros(1, 100, 'uint64');
            prime(1) = prevprime(uint64(inf));
            for x = 2:100
                prime(x) = prevprime(prime(x-1)) - 1;
            end


            tic, isprime(prime); toc
            % Elapsed time is 206.562121 seconds.

            timeit(@() isprime_fast(prime))
            % 0.1442

            sPrime = sym(prime);
            timeit(@() isprime_fast(sPrime))
            % 0.0284
        end

        function oneHundredPseudoPrimesBelowFlintmax(~)
            % find pseudoprimes with high (> 20M) factors
            % flintmax = 2^53
            found = [];
            start = uint64(2^53);
            x = 1;
            while numel(found) ~= 100
                num = start + x;
                f = factor(sym(num));
                f = double(f);
                if numel(f) == 2 && f(1) > 20000000
                    disp(int64(num));
                    found = [found, num]; %#ok<AGROW>
                end
                x = x + 2;
            end
        end

        function loadFlintmax(testCase)
            pseudoprimes = load("greaterThanFlintmax.mat").found;
            testCase.assertLength(pseudoprimes, 100);
            tic, isprime(pseudoprimes); toc
            tic, isprime_fast(pseudoprimes); toc
            sPseudoprimes = sym(pseudoprimes);
            tic, isprime(sPseudoprimes); toc
        end

        function normalDistribBits16(~)
            % Normal distribution of 1 million primes with mean 2^16
            input = abs(floor(normrnd(2^16, 2^13, [1, 10000])));
            input = nextprime(input);
            input = repmat(input, [1, 100]);
            disp(size(input));
            disp("Max: " + max(input));
            disp("Min: " + min(input));
            tic, isprime(input); toc
            timeit(@() isprime_fast(input))
            % 11 seconds
        end

        function normalDistribBits32(~)
            % Normal distribution of 100,000 random odd numbers with mean 2^32
            input = abs(floor(normrnd(2^32, 2^30, [1, 100000])));
            % convert to odd numbers
            evenIdx = mod(input, 2) == 0;
            input(evenIdx) = input(evenIdx) + 1;
            %input = nextprime(input);
            %input = repmat(input, [1, 20]);
            disp(size(input));
            disp("Max: " + max(input));
            disp("Min: " + min(input));
            tic, isprime(input); toc
            tic, isprime_fast(input); toc
            % 21 seconds
        end

        function shortTinyPrimeArray(testCase)
            % Short array of tiny primes
            input = 1000:2000;
            input = nextprime(input);
            input = unique(input);
            testCase.assertLength(input, 136);
            sInput = sym(input);

            t1 = 0;
            t2 = 0;
            numTrials = 50;
            for x = 1:numTrials
                t1 = t1 + timeit(@() isprime(input));
                t2 = t2 + timeit(@() isprime_fast(input));
            end
            t1 = t1/numTrials;
            t2 = t2/numTrials;
            t3 = timeit(@() isprime(sInput));
            disp(t1);
            disp(t2);
            disp(t3);
        end
    end
end

function [t1, t2, t3] = getPerf(numBits, checkPrime)
    low = 2^(numBits - 1);
    high = 2^numBits - 1;
    if numBits >= 53
        num = 4;
        if checkPrime
            num = uint64(2)^numBits - randi(2^53 - 1);
            num = prevprime(num);
        else
            while mod(num, 2) == 0
                % randi only supports < 2^53
                % instead take high number and subtract largest randi range
                % this skews data toward high side of numBits, but it sufficient
                % for basic performance testing
                num = uint64(2)^numBits - randi(2^53 - 1);
            end
        end
    else
        num = 4;
        if checkPrime
            num = nextprime(randi([low, high]));
        else
            while mod(num, 2) == 0
                num = randi([low, high]);
            end
        end
    end

    if checkPrime
        assert(isprime(sym(num)));
    else
        assert(mod(num, 2) == 1);
    end

    if num < 2^47
        t1 = timeit(@() isprime(num));
    else
        % built-in becomes a little slow for timeit
        tic;
        %isprime(num);
        t1 = toc;
    end
    t2 = timeit(@() isprime_fast(num));
    sNum = sym(num);
    t3 = timeit(@() isprime(sNum));
end
