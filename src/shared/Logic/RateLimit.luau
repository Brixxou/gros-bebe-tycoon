--!strict
-- Limiteur de fréquence par seau de jetons : `rate` jetons par seconde, au plus `burst` d'avance.

export type Limiter = {
	rate: number,
	burst: number,
	buckets: { [any]: { tokens: number, at: number } },
}

local RateLimit = {}

function RateLimit.new(rate: number, burst: number): Limiter
	return { rate = rate, burst = burst, buckets = {} }
end

function RateLimit.allow(limiter: Limiter, key: any, now: number): boolean
	local bucket = limiter.buckets[key]
	if bucket == nil then
		bucket = { tokens = limiter.burst, at = now }
		limiter.buckets[key] = bucket
	end
	bucket.tokens = math.min(limiter.burst, bucket.tokens + (now - bucket.at) * limiter.rate)
	bucket.at = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

function RateLimit.forget(limiter: Limiter, key: any)
	limiter.buckets[key] = nil
end

return RateLimit
