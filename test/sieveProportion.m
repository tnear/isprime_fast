% Helper utility for calculating prime metadata (not directly used by isprime_fast)
function [proportionOfNewPrime, numAdded, cycle] = sieveProportion(prime)
    assert(isprime(prime));
    p = primes(prime);
    cycle = prod(p);
    result = false(1, cycle);
    for val = p
        if val == prime
            % last prime
            before = nnz(result);
        end
        result(val : val : end) = true;
        after = nnz(result);

        if val == prime
            numAdded = after - before;
            proportionOfNewPrime = numAdded / cycle;
        end
    end
end
