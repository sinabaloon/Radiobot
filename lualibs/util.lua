util = {}

function util.SaveToFile( tbl,filename )
	local charS,charE = "   ","\n"
	local file,err

	-- create a pseudo file that writes to a string and return the string
	if not filename then
		file =  { write = function( self,newstr ) self.str = self.str..newstr end, str = "" }
		charS,charE = "",""
	-- write table to tmpfile
	elseif filename == true or filename == 1 then
		charS,charE,file = "","",io.tmpfile()
		-- write table to file
		-- use io.open here rather than io.output, since in windows when clicking on a file opened with io.output will create an error
	else
		file,err = io.open( filename, "w" )
		if err then return _,err end
	end

	-- initiate variables for save procedure
	local tables,lookup = { tbl },{ [tbl] = 1 }
	file:write( "return {"..charE )
	for idx,t in ipairs( tables ) do
		if filename and filename ~= true and filename ~= 1 then
			file:write( "-- Table: {"..idx.."}"..charE )
		end
		file:write( "{"..charE )
		local thandled = {}
		for i,v in ipairs( t ) do
			thandled[i] = true
			-- escape functions and userdata
			if type( v ) ~= "userdata" then
			-- only handle value
				if type( v ) == "table" then
					if not lookup[v] then
						table.insert( tables, v )
						lookup[v] = #tables
					end
					file:write( charS.."{"..lookup[v].."},"..charE )
				elseif type( v ) == "function" then
					file:write( charS.."loadstring(".._exportstring(string.dump( v )).."),"..charE )
				else
					local value =  ( type( v ) == "string" and _exportstring( v ) ) or tostring( v )
					file:write(  charS..value..","..charE )
				end
			end
		end
		for i,v in pairs( t ) do
			-- escape functions and userdata
			if (not thandled[i]) and type( v ) ~= "userdata" then
				-- handle index
				if type( i ) == "table" then
					if not lookup[i] then
						table.insert( tables,i )
						lookup[i] = #tables
					end
					file:write( charS.."[{"..lookup[i].."}]=" )
				else
					local index = ( type( i ) == "string" and "[".._exportstring( i ).."]" ) or string.format( "[%d]",i )
					file:write( charS..index.."=" )
				end
				-- handle value
				if type( v ) == "table" then
					if not lookup[v] then
						table.insert( tables,v )
						lookup[v] = #tables
					end
					file:write( "{"..lookup[v].."},"..charE )
				elseif type( v ) == "function" then
					file:write( "loadstring(".._exportstring(string.dump( v )).."),"..charE )
				else
					local value =  ( type( v ) == "string" and _exportstring( v ) ) or tostring( v )
					file:write( value..","..charE )
				end
			end
		end
		file:write( "},"..charE )
	end
	file:write( "}" )
	-- Return Values
	-- return stringtable from string
	if not filename then
		-- set marker for stringtable
		return file.str.."--|"
		-- return stringttable from file
	elseif filename == true or filename == 1 then
		file:seek ( "set" )
		-- no need to close file, it gets closed and removed automatically
		-- set marker for stringtable
		return file:read( "*a" ).."--|"
	-- close file and return 1
	else
		file:close()
		return 1
	end
end

function util.LoadFromFile( sfile )

	-- catch marker for stringtable
	if string.sub( sfile,-3,-1 ) == "--|" then
		tables,err = loadstring( sfile )
	else
		tables,err = loadfile( sfile )
	end
	if err then return _,err end
	tables = tables()
	for idx = 1,#tables do
		local tolinkv,tolinki = {},{}
		for i,v in pairs( tables[idx] ) do
			if type( v ) == "table" and tables[v[1]] then
				table.insert( tolinkv,{ i,tables[v[1]] } )
			end
			if type( i ) == "table" and tables[i[1]] then
				table.insert( tolinki,{ i,tables[i[1]] } )
			end
		end
		-- link values, first due to possible changes of indices
		for _,v in ipairs( tolinkv ) do
			tables[idx][v[1]] = v[2]
		end
		-- link indices
		for _,v in ipairs( tolinki ) do
			tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
		end
	end
	return tables[1]
end

function _exportstring( s )
	s = string.format( "%q",s )
	-- to replace
	s = string.gsub( s,"\\\n","\\n" )
	s = string.gsub( s,"\r","\\r" )
	s = string.gsub( s,string.char(26),"\"..string.char(26)..\"" )
	return s
end

--Meant for easy, external assembly of simple config tables with strings
function util.LoadConfig(path)
         local str = file.ReadText(path)
         local tbl = {}
         
         if not str then
            return false
         end

         for k,line in pairs(string.Explode(str,"\n")) do
             local Findex = string.find(line,"'")

             if Findex and Findex > 0 then
                line = string.sub(line,1,Findex - 1)
             end

             if string.Trim(line) ~= "" then
                local wordtbl = string.Explode(line,"=")
                
                if wordtbl[1] and wordtbl[2] then
                   local key = string.Trim(wordtbl[1])
                   local value = string.Trim(wordtbl[2])
                
                   --If brackets, make it a table.
                   local foundtbl = string.find(value,"{")
                   local foundtbl2 = string.find(value,"}")

                   if foundtbl then
                      local tblstring = string.sub(value,foundtbl+1,foundtbl2-1)

                      value = string.Explode(tblstring,",")

                      for k,v in pairs(value) do
                          value[k] = string.Trim(v)
                      end
                   end

                   tbl[string.gsub(key," ","_")] = value
                end
             end
         end

         return tbl
end

function printtable(tbl,tab)
         tab = tab or ""
         local spaces = "               "

         for k,v in pairs(tbl) do
             local ToPrint = k..":".. string.sub(spaces,1,15 - string.len(k)) .. tostring(v)
             
             if type(v) == "table" then
                print(tab..k..":")
                printtable(v,"     ")
             else
                print(tab..ToPrint)
             end
         end
end





