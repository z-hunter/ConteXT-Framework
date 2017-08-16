instead_version "1.8.0"
-- open-close сделать стандартизированными



require "framework"

wall = cobj {
	nam = "стена", nam1 = "стену",
	cdsc = "Кирпичная стена.",
	dsc = "", -- dsc есть, значит не отображается объектами-дескрипторами (не будут писать "на полу лежит стена" и т.п.).
	Choices = {
		[Ctake] = false,
	}
};

boo = function (s)
	p"Полка имеет кронштейны для крепления к {wall|стене}";
end;


shielf = cobj {
	--var = {
		Choices = {
			["Ощупать"] = "Полка имеет кронштейны для крепления к {wall|стене}",
			[Cclose] = "Я затворил полку :)",
		},
	--},	
	nam = "полка", nam1 = "полку", nam2 = "полке", nam3 = "полкой",
	dsc = function(s)
		if CountCobj(s) > 0 then
			p "На {wall|стене} висит {книжная полка}.";
			DescribeContainer(s, true);
			-- PrintItems(s, "На полке");
		else
			p "На {wall|стене} висит пустая {книжная полка}.";
		end
	end,
	cdsc = function (s)
		p "Небольшая видавшая виды книжная полка из дерева.";
		DescribeContainer(s);		
		-- PrintItems(s, "На полке");
	end,
	Uses = {
		["book"] = {Cput, "Поставить на полку", function (o)	-- переопределение стандартного поведения контейнера
			p "Вы поставили книгу на полку";
			Take (book, "");
			drop(book, o);
			book.standing = true;
		end },
	},
	
	weight = 10,
	
	Container = { 
		
		on_weight = 10,
		in_weight = 5,
		
		_door = opened, -- "opened", "closed", "locked", false
		dsc_opened = "Полка открыта.",
		dsc_closed = "Полка закрыта.",
		dsc_locked = "Заперто.",
		--dsc_open = "Я открыл полку",
		--dsc_close = "Я закрыл полку",
	},
	
	
};

barrel = cobj{
	
	nam = "бочка", nam1 = "бочку", nam2 = "бочке", nam3 = "бочкой",
	Inherit = shielf,
	dsc = false,
	cdsc = "",
	Container = {
		_door = opened,
	},
	standing = true,
};


book = cobj {
    nam = "книга", nam1 = "книгу",
    cdsc = "Небольшая рукописная книга в кожаном переплёте. На корешке вытеснено: 'INSTEAD'",
    cimg = "images.jpg";
    Choices = {
		[Ctake] = function(s) Take(s,"Вы осторожно взяли книгу") end, -- замещение глобального действия для этого конкретного объекта
		[Cdrop] = function(s) p"Вы бережно положили книгу"; Drop(s) end,-- ./.
        ["Читать"] = "'INSTEAD. Сакральное зерцало знаний для желающих игрища учинять'. Далее идут пару сотен страниц трудночитаемой скорописи.",        
        ["Осмотреть"] = "Книга ручной работы. Похоже она очень старая. Обложка с тиснением потемнела и вытерлась, страницы пожелтели, чернила выцвели, но переплёт всё ещё довольно крепок.",
    },    
}

brick = cobj {
    nam = "кирпич", nam2 = "кирпичи";
    cdsc = "Простой пролетарский кирпич кирпичного цвета, даже осматривать и то нечего.",
    Choices = {		
		["Осмотреть"] = false,			-- подавление глобального действия для этого конкретного объекта
		["AddObj"] = function(s)
			AddObj (s, pl, 1)
		end,
		["RemObj"] = function(s)
			RemObj (s, pl, 1)
		end,
    },
    weight = 1;
}

scissors = cobj {
    nam = "ножницы", 
    cdsc = "Обычные канцелярские ножницы с ручками из пластика.",
    pluralis = true;					-- этот объект всегда во множественном числе
}


main = room {
    nam = "Тест",
    dsc = "Это, так сказать, комната",
    obj = {barrel, shielf, Flo, scissors, book, brick, "wall" };
}
