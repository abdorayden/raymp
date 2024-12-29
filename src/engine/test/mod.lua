local mymath =  {}

mymath.has_sin = false

function mymath.add(a,b)
   print(a+b)
end

function mymath.sub(a,b)
   print(a-b)
end

function mymath.mul(a,b)
   print(a*b)
end

function mymath.div(a,b)
   print(a/b)
end

function mymath.sin(a)
	if mymath.has_sin then
		print("sin")
	else
		print("no sin");
	end
end

return mymath	
