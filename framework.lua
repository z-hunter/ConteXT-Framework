--= Context Framework v.0.1.1   (c) z-Hunter@tut.by , 2012-2016 =--

instead_version "1.8.0"
require "xact";

---> Aliases (константы) ///////////////////////////////////////////////
-- global {
	choice = function(s) Cmenu(s) end;	
	using = function(s, w) Umenu(s, w) end;
	Ctake = "Взять";
	Cdrop = "Выбросить";
	Cput = "Поместить";
	Cputin = "Поместить в";
	Cputon = "Положить на";
	Cputunder = "Положить под";
	Copen = "Открыть";
	Cclose = "Закрыть";
	opened = "opened";
	closed = "closed";
	locked = "locked";
-- };


---> Tools  (служебные функции) //////////////////////////////////

function IsString(s)   
  return type(s) == "string" ;
end;
function IsFunction(s)   
  return type(s) == "function" ;
end;
function IsTable(s)   
  return type(s) == "table" ;
end;   
function nop() end;						-- No Operation

function IsPN(t)                    -- >true if =t is Positive Number or is false/nil
	if not t then return true
	elseif type(t)=="number" and t >= 0 then return true
	else return false
	end;
end;

function IsArray (t)						---> true  if table =t is Array
	if not IsTable then return false end;
	local count = 0;
	for k, _ in pairs(t) do						
		if type(k)~="number" then return false else count = count +1 end;
	end;
	for i=1, count do
		if not t[i] and type(t[i])~="nil" then return false end;
	end;
	return true;
end;

function table.ifind(t, f) -- INDEX find: search for key =f in array =t and return its index
  local v; local i;
  for i, v in ipairs(t) do
    if v == f then
      return i
    end
  end
  return nil
end;


function table.deepcopy(o, seen)  --> recursively copies a table's contents, ensures that metatables are preserved
  -- Handle non-tables and previously-seen tables. |SRC: https://gist.github.com/tylerneylon/81333721109155b2d244#file-copy-lua-L84
  if not IsTable(o) then return o
  elseif seen and seen[o] then return seen[o]
  end;
  -- New table; mark it as seen an copy recursively.
  local s = seen or {};
  s[o] = true;
  local res = setmetatable({}, getmetatable(o));
  local k, v;
  for k, v in pairs(o) do res[table.deepcopy(k, s)] = table.deepcopy(v, s) end;
  return res
end;

-->  
function table.deepmerge(t1, t2, seen)		---> result of recursive merging t2 over t1. For Arrays doing concatenation (adding new indexes)
											-- для МАССИВОВ отсутствует защита от бесконечной рекурсии!
		local k, v, res;									
			
		if IsArray(t2) and IsArray(t1) then				    -- массивы - отдельный случай, Одинаковые индексы не замещаются а добавляются
			res = table.deepcopy(t1)					-- временный буфер чтобы не испортить оригинал									
			for k = 1, #t2 do
				if IsTable(t2[k]) and IsTable(res[k]) then
					res[k] = table.deepmerge(res[k], t2[k])										-- рекурсивно обходим их
				else 
					res[#res+1] = t2[k];
				end;				
			end;
		elseif IsTable(t2) and IsTable(t1) then							-- если и там и там таблицы 
			if seen and seen[t2] then return seen[t2] end;				
			local s = seen or {};
			s[t2] = true;
			res = table.deepcopy(t1)					-- временный буфер чтобы не испортить оригинал									
			for k,v in pairs(t2) do
				if IsTable(v) and IsTable(res[k]) then
					res[k] = table.deepmerge(res[k], t2[k], s)										-- рекурсивно обходим их
				else 
					res[k] = v
				end;
			end;
		else 
			res = t2 or t1														
		end;
		return res;
	
end;


-- XACT section
link = xact( "link", function(_, o)
	o = stead.ref(o)
	Proceed(o.act, o);
end);

cxact = xact( "cxact", function(_, f, o, sup)	--> handler for local context menu items		
        o = stead.ref(o)
		if sup ~= "true" then			-- механизм подавления вывода описания в o.Choices: ["Choice"] = { ... , suppress = true } 
			pchoice("link", o.nam, stead.deref(o)); p ("-> ", f, "^^");
			-- p(txtc( makexact("link", o.nam, stead.deref(o)) ).." -> "..f,"^^");	  -- если не подавлено то выводим описание		
		end;
		clear_usemode(true);						-- сбрасываем режим use
		o.scene_use = true; o.menu_type = true;
		Proceed(o.Choices[f], o);
end);
gcxact = xact( "gcxact", function(_, f, o, sup)	-- ./. for global context menu items
        o = stead.ref(o)
		o.scene_use = false; o.menu_type = true;		-- выключаем режим use если он был
		if sup ~= "true" then			-- suppress = true  
			--p(txtc( makexact("link", o.nam, stead.deref(o)) ).." -> "..f,"^^");	  -- если не подавлено то выводим описание		
		 pchoice("link", o.nam, stead.deref(o)); p ("-> ", f, "^^");	  -- если не подавлено то выводим описание		
		end;
		Proceed(game.Choices[f], o);
end);
ucxact = xact( "ucxact", function(_, o, w)	-- ./. for use-on menu
        o = stead.ref(o);
		-- local wr = stead.ref(w);
		-- wr.scene_use = false; wr.menu_type = true;		-- выключаем режим use если он был
        -- p(txtc(o.nam),": ", w,"^^");
		Proceed(o.Uses[w][2], o);
end);
pcxact = xact( "pcxact", function(_, o, w, T)					-- в контейнер =o помещаем объект =w 
		clear_usemode(true);						-- сбрасываем режим use
		o = stead.ref(o);
		w = stead.ref(w);
		-- p (o.nam, "<", w.nam)
		Put(o,w, T);
end);

p2cxact = xact( "p2cxact", function(_, o, w)					-- обработка заказного помещения в контейнер
												-- ПРИМЕР: в cobj.Uses: ["book"] = {Cput, "Поставить на полку", function() ... end}
		clear_usemode(true);						-- сбрасываем режим use
		o = stead.ref(o);
		Proceed(o.Uses[w][3], o);
end);

occxact = xact ("occxact", function(_, o)			-- обработка открытия/закрытия контейнера
	clear_usemode(true);						-- сбрасываем режим use
	return (container_door_sw(stead.ref(o)));	
end);

-- end of XACT section

function container_door_sw(o)						-- открытие/закрытие контейнера (переключатель)
	if o.Container._door == closed then
		o.Container._door = "opened";
		p ("Я открыл ", o.nam1);
	elseif o.Container._door == "locked" then 
		p(o.Container.dsc_locked);
	else 
		o.Container._door = "closed";
		p("Я закрыл ", o.nam1);
	end;
end;


function pchoice(x, txt, ...)					-- выводит пункт меню, вызывающий xact =x с текстом =txt и списком аргументов =... для xact
	local ret = "{".. x.. "("; 
	local f; for f=1, arg.n do
		ret = ret .. tostring(arg[f])
		if f < arg.n then ret = ret .. ","; end;
	end;	
	ret = ret .. ")|" .. txtnb(txt) .. "}" ;
	p(ret, " | ");	
end; 


function clone_constructor (o)
    return table.deepcopy(o);
end;

function clone(o)    
    return new ([[clone_constructor(]]..stead.deref(o)..[[)]])
end;

function set_dispquantity(o)
	if o._quantity > 1 then
		o.disp = o.nam2.." ("..o._quantity..")";
	else
		o.disp = o.nam
	end;
end;

onload_handler = obj {		
	nam = "on";
	life = function (s)
		if s.nam == "on" then			-- срабатывает на след. ход после загрузки или старта игры
			s.nam = "off"
			for _, v in opairs( objs(me()) ) do		-- поправляем отображение клонов в инвентаре
				set_dispquantity(v);
			end;
		end;
	end;
};
lifeon("onload_handler");

function clear_usemode(f)				-- 	сбрасывет режим use всех объектов в сцене/инвентаре и выставляет menu_type =f	
		local i; local s = here();		-- является частью механизма кот. обеспечивает вывод меню по первому а не второму клику на объект
		for _, i in opairs(objs(s)) do			
			i.scene_use = false; i.menu_type = f;
		end;
		for _, i in opairs(inv()) do			
			i.scene_use = true; i.menu_type = f;
		end;
end;


---> Base Functions   (основные функции) ///////////////////////////////

function Proceed (e, o, w)					-- "Proceed" content of (e). If (e) is single arg, print string or executing function
	local r;						-- If (e) is array, take rnd element and proceed it as above
	
	if IsString(e) then p(e);					-- строка
	elseif IsFunction(e) then return e(o,w);		-- функция
	elseif IsTable(e) then						-- массив (строк и/или функций)
		r = e[rnd(#e)];								-- выбираем случайный эл-т:
		if IsString(r) then p(r);					-- строка
		elseif IsFunction(r) then return r(o,w);		-- функция
		elseif IsTable(r) then error "Proceed: Arg is a incorrect array (no nested arrays allowed)";
		else error "Proceed(): Arg is a incorrect array (array of strings and/or functions expected)";
		end;
	else error "Proceed(): Incorrect arg type (string or array of strings/functions expected)";
	end;
end;


function Cmenu(s)					-- Choice Menu (которое появляется при выборе объекта)
	local txt, fun, k, v, ok;
    clear_usemode(false);
	s.scene_use = true; s.menu_type = false;  -- устанавливаем режим use
	
    if s._quantity == 1 then
		pn( txtc(s.nam));								-- печатаем заголовок
	elseif s._quantity > 1 then
		-- pn(txtc( makexact("link", s.nam.."(".."шт.)", stead.deref(s)  ) ));
		pn(txtc(s.nam.." ("..s._quantity.." шт.)"))
	end;
    if s.cimg then pn(img("img/"..s.cimg));		-- картинку если есть
	else pn();									-- или пустую строку вместо неё
	end; 
    Proceed(s.cdsc, s); p"^^";					-- краткое описание	
	p"> ";	
	
	local function print_pure_choice(s, txt, v, xactnam)
		local C = s.Container -- подавляем закрыть/открыть для не контрейнеров и неподходящих конфигураций дверцы 
		if txt == Copen and (not C._enabled or C._door ~= "closed") then nop();						 					
		elseif txt == Cclose and (not C._enabled or C._door ~= "opened") then nop();	
		elseif txt == Ctake and have(s) then nop();					-- подавляем неактуальные взять/положить
		elseif txt == Cdrop and not have(s) then nop(); --/
		else 			
				pchoice(xactnam, txt, txt, stead.deref(s));			-- выводим акутальные пункты меню
				-- p(txtnb("> "), makexact(xactnam,txt,  txt, stead.deref(s)), " | ");    
				-- p(txtnb("> "),"{xactnam(", txt, ",", stead.deref(s), ",", s.Choices[txt].suppress, ")|", txt, "}  |  ");    
		end;
	end;	

	for txt, v in pairs(s.Choices) do				-- перебираем локальные Choices               						
			if not game.Choices[txt] and table.ifind(s.ActiveChoices, txt) and v then -- 				
							-- подавляем локальные пункты совпадаюшие с глобальными (выводятся ниже вместо глобальных) а также неактивные
				print_pure_choice(s,txt,v, "cxact")
			end;
    end;
	 
    for txt, v in pairs(game.Choices) do				-- а теперь горбат... глобальные Choices					              	
		local C = s.Container
		if s.Choices[txt] == false then nop()			-- подавляем те, которые в объекте переопределены как false
		elseif s.Choices[txt]  then 						-- выводим вместо одноименных глобальных те локальные что подавили ранее			
			print_pure_choice(s,txt,v, "cxact")	 
		-- elseif not table.ifind(game.ActiveChoices, txt) then nop();
		else  							 
			print_pure_choice(s,txt,v, "gcxact")			
		end;
    end;
	
	if s.cscene_use or have(s) then
		s.scene_use = true; s.menu_type = false;
		pchoice(stead.deref(s),"Использовать с...");
		-- p( "{", stead.deref(s), "|", txtnb("Использовать с..."), "}" );
	end;
	
end;

function Umenu(s, w)									-- Menu of Using (when s & w used together)
	w.scene_use = false; w.menu_type = true;		-- выключаем режим use если он был
	local count = 0;
	local cput = false;
	pn(txtc(w.nam.." и "..s.nam))	
	for o, fun in pairs(s.Uses) do	
		if stead.ref(o) == w then
			count = count + 1;
			if fun[1] == Cput then -- у контейнера есть кастомный обработчик замещающий сразу все типы помещения в него
				cput = true;
				pchoice ("p2cxact", fun[2], stead.deref(s), stead.deref(w))
			else
				pchoice ("ucxact", fun[1], stead.deref(s), stead.deref(w))
				-- p("^> {ucxact(", stead.deref(s), ",", stead.deref(w), "|", fun[1], "}");				
			end;	
		end;		
	end;
	-- пункты помещения в контейнер
	if s.Container:IsCapable() and not cput then
		if s.Container.on_weight then
			pchoice("pcxact","Положить на "..s.nam1, stead.deref(s), stead.deref(w),"on");
		end;
		if s.Container.in_weight and not s.Container._door == closed then 
			pchoice("pcxact","Поместить в "..s.nam1, stead.deref(s), stead.deref(w),"in");
		end;
		if s.Container.under_weight then
			pchoice("pcxact","Положить под "..s.nam1, stead.deref(s), stead.deref(w),"under");
		end;
		
		-- pchoice("pcxact","Поместить в "..s.nam1, stead.deref(s), stead.deref(w))
	elseif count == 0 then		
		pn(); Proceed (game.nouse, s, w);
	end;
		
end;



function FloorHere()
	local i, o;
	for i, o in opairs(objs( here() )) do
		if o.floor then
			return o;
			-- break
		end;				
	end;
	return false;
end;

function AddObj (o, w, q)		----> добавляет =q объектов =o в =w
	local i = nil;

	if not q then
		q = 1
	elseif q <= 0 then
		error "AddObj(): arg#3 (quantity) is zero or negative.";
	end;

	_,i = w.obj:srch(o.nam);				-- ищем такой объект у w
	if not i then				 			-- если его нет
		put (clone(o), w);					-- создаём новый клон в w
		_,i = w.obj:srch(o.nam);			-- находим созданное
		w.obj[i]._quantity = 0; 			-- инициализируем атрибут кол-ва
	end;									-- на этом этапе в w гарантированно есть такой объект
	w.obj[i]._quantity = w.obj[i]._quantity + q		-- вычисляем атрибут кол-ва
	set_dispquantity (w.obj[i])				-- корректируем отображаемое название
end;


function RemObj (o, w, q)		----> Убавляет =q объектов =o в =w
	local i = nil;
	
	if q <= 0 then
		error "RemObj(): arg#3 (quantity) is zero or negative.";
	end;
	
	_,i = w.obj:srch(o.nam);
	if i then
		w.obj[i]._quantity = w.obj[i]._quantity - q;	-- вычисляем атрибут кол-ва
		if w.obj[i]._quantity <= 0 then					-- если получилось что отнялось всё
			-- remove (o, w);  	-<-- так не работает
			-- local tmp = seen (o.nam, w);				
			remove (w.obj[i], w);							
		else
			set_dispquantity(w.obj[i])
		end;
	end;

end;

function Take(o, takeok, notake1, notake2)				-- 
	local v;
	local count = 0;
	
	if not takeok then takeok = game.take end;
	if not notake1 then notake1 = game.notake1 end;
	if not notake2 then notake2 = game.notake2 end;
	
	count = o.weight;
	if count > pl.maxweight then
		Proceed(notake1, o);
		return false;
	end;
	for _, v in opairs(objs(pl)) do			-- считаем вес переносимого		
		count = count + v.weight;		
	end;
	if count > pl.maxweight then
		Proceed(notake2, o);
		return false;
	else								-- //// ничто не мешает взять объект
		
		take(o, where(o));				-- берем оттуда, где это лежит (иначе в инвентаре возникнет дубль)
		if o._in_container_slot then o._in_container_slot = false end; 
		if o._dropped then o._dropped = false end;
		Proceed(takeok, o);
		o.dsc = nil;		-- после взятия не нужен dsc тк описание объекта будет генерироваться описателями 
	end;	
end;

-- ..
function Put (w, o, T, putok, noput1, noput2)
	if not T then T = "on" end;
	
	local weight;	
	if T == "in" then
		weight = w.Container.in_weight;  
	elseif T == "on" then
		weight = w.Container.on_weight; 
	elseif T == "under" then
		weight = w.Container.under_weight; 
	end;
	
	o._in_container_slot = T;
	drop(o,w);
	p "вы положили это"
end;

function Drop(o, dropok, nodrop)								--
		local FH = FloorHere();		
		local dropok = o.dropok or game.drop;
		local nodrop = o.nodrop or game.nodrop;
			
		if FH then	
			drop( o, here() );
			-- if not o.dropped then stead.add_var(o, dropped) end;
			o._dropped = true;
			Proceed(dropok, o, FH);			
		else
			Proceed (nodrop, o);
			return false;
		end;				
	

end;

function TransferDropped(f, t)				-- Переносит (копирует) выброшенные игроком объекты из f в t		
		for _, i in opairs(objs(f)) do			
			if i._dropped then place(i, t) end;
		end;
end;


function PrintItems (s, introtxt, T)		-- Non-recursive search and describe all objects in (s) with (introtxt) if any objects here
											-- If optional (T) specified -- proceed only objects with: obj._in_container_slot = T  
		local o_nam={};						-- for "laying" objects
		local o_ref={};	
		local o_nam1={};					-- for "standing" objects
		local o_ref1={};	
		local i, o;
		local plu = false; local plu1 = false;
		local ics;						-- incontainer slot status 
		 				
		for i, o in opairs(objs(s)) do		-- перебираем объекты внутри s
			if T then
				if T == o._in_container_slot then ics = true else ics = false end; 
				if T == "on" and not o._in_container_slot then ics = true end;
			else ics = true
			end;  -- если задан параметр фильтрования контейнера готовим булевый ics
			if not o.dsc and o.nam1 and ics then	-- объекты с dsc сами себя описывают, а объекты без nam1 это не cobj
				set_dispquantity(o)			-- устанавливаем корректное число - мн. или ед.
				if o.standing then 			-- далее сортируем объекты на лежащие и стоящие :)
					table.insert(o_nam1, o.disp);
					table.insert(o_ref1, stead.deref(o));
					if o.pluralis or o._quantity > 1 then plu1 = true end;
				else
					table.insert(o_nam, o.disp);
					table.insert(o_ref, stead.deref(o));			
					if o.pluralis or o._quantity > 1 then plu = true end;
				end;
			end;
		end;		
		
		if #o_nam + #o_nam1 > 0 then 				-- есть что описать
			
			p (introtxt) 
			if #o_nam == 1 and not plu then						-- перечисляем лежащее
				p("лежит {",o_ref[1],"|",o_nam[1],"}");
			elseif #o_nam > 1 or plu then
				p "лежат";
				for i, o in pairs(o_nam) do
					p ("{",o_ref[i],"|",o_nam[i],"}");
					if i < #o_nam - 1 then
						p ", "
					elseif i == #o_nam - 1 then
						p "и";
					end;
				end; 
			end;
			
			if #o_nam > 0 and #o_nam1 > 0 then
				p "а также";
			end;
			
			if #o_nam1 == 1 and not plu1 then					-- перечисляем стоящее
				p("стоит {",o_ref1[1],"|",o_nam1[1],"}");
			elseif #o_nam1 > 1 or plu1 then
				p "стоят";
				for i, o in pairs(o_nam1) do
					p ("{",o_ref1[i],"|",o_nam1[i],"}");
					if i < #o_nam1 - 1 then
						p ","
					elseif i == #o_nam1 - 1 then
						p "и";
					end;
				end; 
			end;
			
			p "."
		
		end;
end;



function DescribeContainer(s, vis)		-- Выводит описание содержимого контейнера с учетом слотов "в/на/под" и закрытой/открытой дверцы
											-- vis (optional) if ==true: proceed only "on" (always) and "in" (if not closed) objs in container
	local closed = s.Container._door;
	
	if not vis then 
		if closed then
			p (s.Container.dsc_closed);
		elseif s.Container._door and s.Container._door == "opened" then
			p (s.Container.dsc_opened);
		end;
	end;
	
	PrintItems(s, "На "..s.nam2, "on");	
	if not closed then 
		PrintItems(s, "В "..s.nam2, "in");
	end;
	if not vis then
		PrintItems(s, "Под "..s.nam3, "under")
	end;
end;

function CountCobj(s)					-- Non-recursive counts cobj in some other object
	local i, o;
	local count = 0
	for i, o in opairs(objs(s)) do
		if not o.dsc and o.nam1 then				-- объекты с dsc нам не интересны так как сами себя описывают
			count = count +1;
		end;		
		-- p (stead.nameof(o));;
		-- p (o.nam);
	end;
	-- p(count);
	return count;
end;


function AddChoice(s, c)
	table.insert (s.ActiveChoices, c);
end;

function RemChoice(s, c)
	table.remove (s.ActiveChoices, table.ifind(s.ActiveChoices, c));
end;


function cobj(v)							---  ||||||||||||||||||| extended standart obj |||| |     |           |	
	local i; 
		
	if v.Inherit then						--- этот объект наследует параметры другого объекта =Inherit		
		v = table.deepmerge(v.Inherit, v);   		
	end;
	 		
	if not v.Choices then
		v.Choices = {}; v.ActiveChoices = {};
	end;
	if not v.ActiveChoices then
		v.ActiveChoices = {};
		for i, _ in pairs(v.Choices) do
			AddChoice(v, i)
		end;
	end;
	if v.InactiveChoices then
		for _, i in pairs(v.InactiveChoices) do
			RemChoice(v, i)
		end;
	end;
	
	v.cdsc = v.cdsc or "";
	-- if not v.cdsc then error ("cobj "..v.nam..": none of .cdsc and .dsc is defined.") end;
	v.Uses = v.Uses or {};
	v.act = v.act or choice
	v.inv = v.inv or choice;
	v.used = v.used or using;
	v.nam1 = v.nam1 or v.nam;				-- nam1 = nam в винительном падеже (accusative, кого что?)   
	v.nam2 =	 v.nam2 or v.nam;			  	-- nam2 = nam в множ. числе (nam in pluralis)
	v.weight = v.weight or 0;
	
	v._quantity = v._quantity or 1; --  
	-- v.id = stead.deref(v);
	
	if v.scene_use then						-- cobj используются через меню
		stead.add_var(v, {cscene_use = true});
		v.scene_use = false;
	end;
	 
	
	--- начало секции инициализации Container	
	if v.Container then
		v.Container._enabled = true;
	else 
		v.Container = {};
	end;
	local C = v.Container;
			
	C.parent = v;
	if C._door and (C._door~=closed and C._door~=opened and C._door~=locked) then
		error ("cobj "..v.nam..": Container._door must be = opened, closed or locked (now= "..C._door..")");
	end;
			
	if  IsPN(C.in_weight) and IsPN(C.on_weight) and IsPN(C.under_weight) then
			nop();
	else
			error ("cobj "..v.nam..": Container.*_weight values must be a positive numbers.");
	end;
	
	C.IsCapable = function(s)     -- возвращает True если этот объект может служить контейнером
		if s._enabled and (s.in_weight > 0 or s.on_weight > 0 or s.under_weight > 0) then return true;
		else return false;
		end;
	end;
	
	C.SlotBurden = function(s, slot)    -- ex: slot_weight = somecobj.Container:SlotBurden("in")
		local i;
		local c = 0;
		local X = s.parent
		p ("*"..X.nam);
		for _, i in opairs(objs( X )) do			
			p (i.nam)
			if i._in_container_slot == slot  then c = c + i.weight end;		
		end;
		return c
	end;
	v.var = v.var or {};
	v.var.Container = C;
	--C = nil;
															--- конец секции Container
	
	return obj(v);
end;

function cmenu(v)							--- extended standart menu
	cobj(v)
	menu(v);
	v.act = choice;
	v.inv = choice;
	return v;
end; 




---> Game-specific variables and functions  ////////////////////////////


Flo = cobj {									--- object-descriptor for "floor"
	nam = "пол",								-- объект-описатель для лежащих на полу объектов
	dsc = function(s)
		PrintItems (here(), "На полу");
	end,
	floor = true,								-- Drop function look for this. If here no objects with floor, drop is impossible
};

Gro = cobj {									--- "ground"
	nam = "земля", nam1 = "землю",								-- объект-описатель для лежащих на земле объектов
	dsc = function(s)
		PrintItems (here(), "На земле");
	end,
	floor = true,								-- Drop function look for this. If here no objects with floor, drop is impossible
};

Her = cobj {									--- "here"
	nam = "здесь", nam1 = "сюда",								-- объект-описатель для лежащих "здесь" объектов
	dsc = function(s)
		PrintItems (here(), "Здесь");
	end,
	floor = true,								-- Drop function look for this. If here no objects with floor, drop is impossible
};

game.Choices = {										-- global cmenu items, выводятся у всех объектов (если локально не задизаблены в них)

	["Осмотреть"] = function(s) Proceed ({
			"Ничего особенного", "Тут особо нечего осматривать",
			"Просто "..s.nam..".",
			"Я осмотрел "..s.nam1.." но не нашёл ничего интересного.",
	})end, 

 
	["Ощупать"] = function(s) Proceed ({
			"Я потрогал "..s.nam1..". Вроде бы ничего особенного.",
			"Я ощупал "..s.nam1.." но ничего интересного не обнаружил.",
			"Довольно простая фактура. ",
			"По форме похоже на "..s.nam1..".",
			"Мои пальцы скользят по поверхности, но ничего не обнаруживают.",
			"На ощупь "..s.nam.." как "..s.nam..", ничего примечательного.",
			function(o)
				if o.Container.in_weight then
						p("При постукивании пальцами по поверхности ",o.nam);
						p" иногда звучит как пустотелый объект.";
					else
						p("На ощупь "..o.nam.." производит ощущение чего-то однородного.");
				end;
			end,
			function(o)
				if o.Container.on_weight then
					p("Верхняя часть довольно плоская.");
				else p "Довольно гладкая поверхность.";
				end;
			end,
	},s) end, 

	[Ctake] = function(s)
		Take(s, game.take);
	end,
  
	[Cdrop] = function(s)
		Drop (s, game.drop);
	end, 
	
	[Copen] = function(s)
		-- p (S.nam)
		p (s.Container:SlotBurden("on"));
	end,
	
	[Cclose] = function(s)
	end,
	
};

--[[ stead.add_var(game, {
	ActiveChoices = {Ctake, Cdrop, "Ощупать", "Осмотреть"};
})]]


pl.maxweight = 10;

-- Default output of Take() if o.weight > pl.maxweight
game.notake1 = {
	"Предмет слишком тяжёл чтобы его взять. ",
	function (s) p("Мне не поднять", s.nam1,".") end,
	"Слишком тяжело.",
	function (s) p("Напрягая все мышцы пытаюсь приподнять ", s.nam1, ". Нет, это бессмысленно.") end,
	function (s) p("У меня не хватит сил чтобы поднять ", s.nam1) end,
};												

-- o.weight + invetory weight > pl.maxweight
game.notake2 = {
	"Мне некуда это взять.",
	"Я и так несу слишком много.",
	"Чтобы взять это надо сначала что-то выбросить.",
	"Мне столько не унести.",
	"Не могу взять. Руки заняты."
	};												

-- Take successfully
game.take = {
	function (s)		
		if s.weight > ((pl.maxweight / 2) + 1 ) then
			Proceed ({
				"Тяжёлый предмет у меня в руках.",
				"Громоздкая штука.",
				s.nam.." весит немало, но нести можно.",
			});
		else
			p ("Я взял ", s.nam1,".");
		end;
	end,
	"Это может пригодится.", "Взято.",
	function (s)
		if s.weight > (pl.maxweight / 2) then
			p ("С некоторым усилием я поднял ", s.nam1);
		else
			p ("Я поднял ", s.nam1,".");
		end		
	end,
};
-- Drop successfully
game.drop = {
	function (s, w) 
		if s.standing then
			p( "Я поставил ", s.nam1, " на ", w.nam1, ".")
		else	
			p( "Я положил ", s.nam1, " на ", w.nam1, ".")
		end;
	end,
	"Пусть полежит здесь.",	
};	

-- umenu is empty
game.nouse = {
	"Не знаю как скомбинировать.", "Многообещающее сочетание.",
	"Не могу придумать как это использовать.", "Не знаю как.",
	"Не вижу вариантов использования.", "Никаких идей.", "Ума не приложу как они связаны.",
	"Совместно использовать эти объекты в таком порядке нельзя.", "Какими-то глупостями я занимаюсь.",
	"Cтранные мысли приходят в голову.", "Так можно сойти с ума...", "Не вижу в этом смысла. ",
	"Это издевательство над здравым смыслом.", "Отказываюсь думать про это.",
	"Не получится.", "Страшно...", "Нет вариантов использования.", "Нет идей по поводу применения всего этого.",
	"Не выйдет.", "Ничего придумать тут не могу.", "Это не сработает.", "Так нельзя.", "И что с этим можно сделать?",
	"Не комбинируется.", "Если бы это было так просто...", "Не думаю, что стоит пытаться их совместить.", "Да вы шутите?",
	function (s, w)
		Proceed {"Я не знаю как применить ".. w.nam1 .. " на ".. s.nam1..".",
				"К сожалению, " .. w.nam1 .. " и ".. s.nam1.." скомбинировать невозможно.",
		};
	end,
	function (s, w)	
		p ("Гм... ", w.nam1," в ", s.nam1, "? ");
		Proceed {
			"Не думаю что такое возможно.", "Оригинально.", "Не стоит.", "", "", "",
			"Хорошая идея для авангардного стихотворения.", "Попахивает какими-то извращениями.",
		}
	end,
};

-- No floor surface to drop
game.nodrop = {
	"В таком месте лучше ничего не выбрасывать.",
	"Сперва надо найти куда положить это.",
	"Надо отыскать подходящую поверхность.",
	"Если я выпущу здесь предмет из рук, он упадёт и потеряется.",
	function (s)
		p("Положить ", s.nam1," в воздух? ")
		Proceed({
			"Ну уж нет.", "Нужно что-то более твёрдое.", "Не выйдет.",
		});
	end,
}

game.act = 'Что это?';
game.inv = 'Странный предмет.';
game.use = 'Не получится.';
