--= PILOT Framework for INSTEAD (c) z-Hunter@tut.by, 2013 =--

instead_version "1.8.0"
require "xact";

---> Aliases (константы) ///////////////////////////////////////////////
-- global {
	choice = function(s) Cmenu(s) end;	
	using = function(s, w) Umenu(s, w) end;
	Ctake = "Взять";
	Cdrop = "Выбросить";	
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
function nop()						-- No Operation
end;

function table.ifind(t, f) -- find key =f in array =t and return its index
  local v; local i;
  for i, v in ipairs(t) do
    if v == f then
      return i
    end
  end
  return nil
end;

function table.deepcopy(t)	--> recursively copies a table's contents, ensures that metatables are preserved (correctly clone a pure Lua object)
	local k; local v;
	if not IsTable(t) then return t end
	local mt = getmetatable(t)
	local res = {}
	for k,v in pairs(t) do
		if IsTable(v) then
			v = table.deepcopy(v)
		end
		res[k] = v
	end
	setmetatable(res,mt)
	return res
end


link = xact( "link", function(_, o)
	o = stead.ref(o)
	Proceed(o.act, o);
end);

cxact = xact( "cxact", function(_, f, o)	--> convert string to hyperlink for local context menu items		
        o = stead.ref(o)
        p(txtc(f.." "..o.nam1),"^^");
        Proceed(o.Choices[f], o);
end);
gcxact = xact( "gcxact", function(_, f, o)	-- ./. for global context menu items
        o = stead.ref(o)
        p(txtc(f.." "..o.nam1),"^^");
		Proceed(game.Choices[f], o);
end);
ucxact = xact( "ucxact", function(_, o, w)	-- ./. for use-on menu
        o = stead.ref(o)
        -- p(txtc(o.nam),": ", w,"^^");
		Proceed(o.Uses[w][2], o);
end);

function clone_constructor (s)
    -- local ret = table.deepcopy(s);
    -- set_namquantity(ret)
    return table.deepcopy(s);
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
    
    if s._quantity == 1 then
		pn(txtc(s.nam))								-- печатаем заголовок
	elseif s._quantity > 1 then
		pn(txtc(s.nam.." ("..s._quantity.." шт.)"))
	end;
    if s.cimg then pn(img("img/"..s.cimg));		-- картинку если есть
	else pn();									-- или пустую строку вместо неё
	end; 
    Proceed(s.cdsc, s); p"^^";					-- краткое описание
    
	for txt, fun in pairs(s.Choices) do				-- перебираем локальные Choices               	
		if txt == Ctake and have(s) then nop();			-- не выводим неактуальные взять/положить
		elseif txt == Cdrop and not have(s) then nop(); --/
		else 
			if not game.Choices[txt] and table.ifind(s.ActiveChoices, txt) then 				-- подавляем локальные пункты совпадаюшие с глобальными
				p(txtnb("> "),"{cxact(", txt, ",", stead.deref(s), "|", txt, "}  |  ");    
			end;
		end;				
	end;
    
    for txt, fun in pairs(game.Choices) do					-- а теперь горбат... глобальные Choices               	
		if s.Choices[txt] == false then nop()			-- подавляем те, которые в объекте переопределены как false
		elseif txt == Ctake and have(s) then nop();			-- не выводим неактуальные взять/положить
		elseif txt == Cdrop and not have(s) then nop();		--/
		elseif not table.ifind(game.ActiveChoices, txt) then nop();
		elseif s.Choices[txt] then 						-- выводим вместо одноименных глобальных те локальные что подавили ранее
			p(txtnb("> "),"{cxact(", txt, ",", stead.deref(s), "|", txt, "}  |  ");
		else
			p(txtnb("> "),"{gcxact(", txt, ",", stead.deref(s), "|", txt, "}  |  ");			
		end;
    end;
end;

function Umenu(s, w)									-- Menu of Using (when s & w used together)
	local count = 0;
	pn(txtc(w.nam.." и "..s.nam))	
	for o, fun in pairs(s.Uses) do	
		if stead.ref(o) == w then
			p("^> {ucxact(", stead.deref(s), ",", stead.deref(w), "|", fun[1], "}");
			count = count + 1; 			
		end;		
	end;
	if count == 0 then
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

	if q <= 0 then
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
	local k, v;
	local count = 0;
	
	if not takeok then takeok = game.take end;
	if not notake1 then notake1 = game.notake1 end;
	if not notake2 then notake2 = game.notake2 end;
	
	count = o.weight;
	if count > pl.maxweight then
		Proceed(notake1, o);
		return false;
	end;
	for k, v in opairs(objs(pl)) do			-- считаем вес переносимого		
		count = count + v.weight;		
	end;
	if count > pl.maxweight then
		Proceed(notake2, o);
		return false;
	else
		take(o, here());
		o.taken = true;
		Proceed(takeok, o);
		o.dsc = nil;		-- после взятия не нужен dsc тк описание объекта будет генерироваться описателями 
	end;	
end;

function Drop(o, dropok, nodrop)								--
		local FH;
		
		if not dropok then dropok = game.drop end;
		if not nodrop then nodrop = game.nodrop end;
		
		FH = FloorHere()
		if FH then	
			drop( o, here() );
			o.taken = false;
			Proceed(dropok, o, FH);			
		else
			Proceed (nodrop, o);
			return false;
		end;				
	

end;

function PrintItems (s, introtxt)			-- Non-recursive search anf describe all objects in (s) with (introrext) if any objects here
		local o_nam={};						-- for "laying" objects
		local o_ref={};	
		local o_nam1={};					-- for "standing" objects
		local o_ref1={};	
		local i, o;
		local plu = false; local plu1 = false; 		
		for i, o in opairs(objs(s)) do		-- перебираем объекты внутри s
			if not o.dsc and o.nam1 then	-- объекты с dsc сами себя описывают, а объекты без nam1 это не cobj, значит нам не интересны
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

function CountItems(s)					-- Non-recursive counts object in some other object
	local i, o;
	local count = 0
	for i, o in opairs(objs(s)) do
		-- if IsFunction(o) then nop()
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

function cobj(v)							--- extended standart obj	
	local i; 
	obj(v);
	if not v.Choices then
		v.Choices = {}; v.ActiveChoices = {};
	end;
	if not v.Uses then v.Uses = {} end;
	if not v.act then v.act = choice end;
	if not v.inv then v.inv = choice end;
	if not v.used then v.used = using end;
	if not v.nam1 then v.nam1 = v.nam end;  -- nam1 = nam в винительном падеже (accusative, кого что?)
	if not v.nam2 then v.nam2 = v.nam end;  -- nam2 = nam в множ. числе (nam in pluralis)
	if not v.weight then v.weight = 0 end;
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
	if not v._quantity then v._quantity = 1 end; -- 
	-- if not v.taken then v.taken = false; end; -- 
	v.id = stead.deref(v);
	return v;
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

game.Choices = {										-- global cmenu items, выводятся у всех объектов (если локально не задизаблены в них)

	["Осмотреть"] = function(s) Proceed ({
			"Ничего особенного", "Тут особо нечего осматривать",
			"Просто "..s.nam..".",
			"Я осмотрел "..s.nam1.." но не нашёл ничего интересного.",
	}) end, 

 
	["Ощупать"] = function(s) Proceed ({
			"Я потрогал "..s.nam1..". Вроде бы ничего особенного.",
			"Гм... "..s.nam1.."даёт довольно скудные тактильные ощущения.",
			"Я ощупал "..s.nam1.." но ничего интересного не обнаружил.",
			"Довольно простая фактура. ", "На ощупь "..s.nam.." производит ощущение чего-то однородного.",
			"Довольно гладкая поверхность.", "По форме похоже на "..s.nam1..".",
			"Мои пальцы скользят по поверхности, но ничего не обнаруживают.",
			"На ощупь "..s.nam.." как "..s.nam..", ничего примечательного.",
	}) end, 

	[Ctake] = function(s)
		Take(s, game.take);
	end,
  
	[Cdrop] = function(s)
		Drop (s, game.drop);
	end, 
	
};

stead.add_var(game, {
	ActiveChoices = {Ctake, Cdrop, "Ощупать"};
})


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
game.notake2 = "Мне некуда это взять, руки заняты. ";												

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
	"Не знаю как это можно скомбинировать.", "Ума не приложу что с этим делать. ", "Нет вариантов действий. ", 
	"Я пока не вижу вариантов использования этого.", "Никаких идей.", "Гм...",
	"Совместно использовать эти объекты в таком порядке нельзя.", "Какими-то глупостями я занимаюсь.",
	"Cтранные мысли приходят в голову.", "Так можно сойти с ума...", "Ничего сделать с этим нельзя. ",
	"Это какое-то издевательство над здравым смыслом.", "Не могу придумать что с этим делать.",
	function (s, w) 
		p ("Гм... ", w.nam1," в ", s.nam1, "? ");
		Proceed {
			"Абсурд!", "Зачем?", "Как?", "Сам удивляюсь своей фантазии.", ""
		}
	end,
};

-- No floor surface to drop
game.nodrop = {
	"Некуда положить",
	"Тут нет ни пола, ни земли, чтобы поставить на них. Надо найти подходящую поверхность.",
	function (s) p("На что бы тут положить ", s.nam1,"? ") end,
	"Если я выпущу здесь предмет из рук, он упадёт и потеряется.",
	function (s)
		p("Положить ", s.nam1," в воздух?")
		Proceed({
			"Ха-ха!", "Нужно что-то более твёрдое.", "Не выйдет.",
		});
	end,
}

game.act = 'Что это?';
game.inv = 'Странный предмет.';
game.use = 'Не получится.';
