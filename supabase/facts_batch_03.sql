-- 7 nowych kategorii i 70 ciekawostek, po 10 w każdej.
-- Uruchom raz w SQL Editor. Ponowne uruchomienie nie tworzy duplikatów.

insert into public.categories (name) values
  ('Popkultura & Gry'),
  ('Biznes & Pieniądze'),
  ('Zagadki Codzienności'),
  ('Ciało & Jedzenie'),
  ('Geografia & Miejsca'),
  ('Absurdy Prawa'),
  ('Język & Symbole')
on conflict (name) do nothing;

insert into public.facts
  (id, title, category, short_text, long_text, source_label, source_url, quiz, status)
values
  ('fact-151', 'Klocki z Moskwy', 'Popkultura & Gry', 'Tetris powstał w 1984 roku w radzieckiej akademii nauk.', 'Aleksiej Pażytnow napisał grę w moskiewskim ośrodku komputerowym, testując możliwości maszyny Elektronika 60.

Nazwa łączy słowo „tetra”, bo każdy klocek ma cztery pola, z „tenisem”, ulubionym sportem autora.', 'Wikipedia, „Tetris”', 'https://pl.wikipedia.org/wiki/Tetris', '{"question": "Od czego pochodzi końcówka nazwy Tetris?", "options": ["Od tenisa", "Od terminala", "Od turnieju"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-152', 'Puck zamiast Pac', 'Popkultura & Gry', 'Pac-Man miał się nazywać Puck Man. Bano się jednak żartownisiów.', 'Tak nazywała się japońska wersja z 1980 roku. Przed wejściem na rynek amerykański nazwę zmieniono.

Wydawca obawiał się, że wandale dorysują na automatach jedną kreskę i zmienią literę P w F.', 'Wikipedia, „Pac-Man”', 'https://en.wikipedia.org/wiki/Pac-Man', '{"question": "Czego obawiano się przy nazwie Puck Man?", "options": ["Sporu z ligą hokejową", "Przeróbek na automatach", "Trudnej wymowy"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-153', 'Hydraulik, który był cieślą', 'Popkultura & Gry', 'Mario zadebiutował w 1981 roku jako cieśla o imieniu Jumpman.', 'W grze Donkey Kong bohater nie był jeszcze hydraulikiem ani nie nazywał się Mario.

Imię dostał później, od Mario Segale, właściciela magazynu wynajmowanego przez amerykański oddział Nintendo.', 'Wikipedia, „Mario”', 'https://en.wikipedia.org/wiki/Mario', '{"question": "Po kim Mario odziedziczył imię?", "options": ["Po wynalazcy konsoli", "Po synu twórcy", "Po właścicielu magazynu"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-154', 'Starsze niż samochód', 'Popkultura & Gry', 'Nintendo powstało w 1889 roku jako producent kart do gry.', 'Firma założona w Kioto robiła ręcznie malowane karty hanafuda.

Przez dekady próbowała różnych biznesów, zanim w latach 70. XX wieku na dobre weszła w gry elektroniczne.', 'Wikipedia, „Nintendo”', 'https://pl.wikipedia.org/wiki/Nintendo', '{"question": "Co Nintendo produkowało na początku?", "options": ["Karty do gry", "Zabawki z drewna", "Zegarki"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-155', 'Wiedźmin z konkursu', 'Popkultura & Gry', 'Wiedźmin narodził się w 1986 roku jako opowiadanie na konkurs.', 'Andrzej Sapkowski wysłał tekst do konkursu miesięcznika „Fantastyka” i zajął trzecie miejsce.

Dwie dekady później, w 2007 roku, CD Projekt wydał pierwszą grę o Geralcie, a seria stała się światowym hitem.', 'Wikipedia, „Wiedźmin”', 'https://pl.wikipedia.org/wiki/Wiedźmin', '{"question": "Gdzie po raz pierwszy ukazał się Wiedźmin?", "options": ["W radiu", "W miesięczniku „Fantastyka”", "W grze komputerowej"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-156', 'Gra wszech czasów', 'Popkultura & Gry', 'Minecraft to najlepiej sprzedająca się gra wideo w historii.', 'Sprzedano ponad 300 milionów kopii. Żadna inna gra nie osiągnęła takiego wyniku.

Zaczął ją samodzielnie Szwed Markus Persson. W 2014 roku jego studio Mojang kupił Microsoft za 2,5 miliarda dolarów.', 'Wikipedia, „Minecraft”', 'https://en.wikipedia.org/wiki/Minecraft', '{"question": "Kto kupił studio Mojang?", "options": ["Sony", "Nintendo", "Microsoft"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-157', 'Gra przeciw monopolom', 'Popkultura & Gry', 'Pierwowzór Monopoly miał ostrzegać przed monopolami.', 'Lizzie Magie opatentowała w 1904 roku The Landlord''s Game, by pokazać, jak skupianie ziemi w jednych rękach szkodzi innym.

Dopiero po latach gra w zmienionej wersji trafiła do wydawnictwa Parker Brothers jako Monopoly.', 'Wikipedia, „Monopoly”', 'https://en.wikipedia.org/wiki/Monopoly_(game)', '{"question": "Co miał pokazywać pierwowzór Monopoly?", "options": ["Szkody z monopoli", "Zasady giełdy", "Historię kolei"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-158', 'Słowa, które nie padły', 'Popkultura & Gry', 'Sherlock Holmes nie mówi w książkach „Elementarne, drogi Watsonie”.', 'W opowiadaniach Arthura Conana Doyle''a detektyw używa osobno słowa „elementarne” i zwrotu „mój drogi Watsonie”, ale nigdy razem.

Słynne zdanie rozpowszechniły późniejsze adaptacje.', 'Wikipedia, „Sherlock Holmes”', 'https://en.wikipedia.org/wiki/Sherlock_Holmes', '{"question": "Skąd wzięło się słynne zdanie Holmesa?", "options": ["Z listu Doyle''a", "Z późniejszych adaptacji", "Z pierwszej powieści"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-159', 'Zdanie, które wszyscy mylą', 'Popkultura & Gry', 'Darth Vader nigdy nie mówi „Luke, jestem twoim ojcem”.', 'W filmie „Imperium kontratakuje” pada: „Nie, to ja jestem twoim ojcem”. Imię Luke''a w tej kwestii się nie pojawia.

To przykład zbiorowego błędu pamięci. Miliony ludzi pamiętają cytat, którego nie ma.', 'Wikipedia, „Darth Vader”', 'https://en.wikipedia.org/wiki/Darth_Vader', '{"question": "Czego brakuje w prawdziwej kwestii Vadera?", "options": ["Słowa „ojcem”", "Imienia Luke", "Słowa „jestem”"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-160', 'Pierwszy cały z komputera', 'Popkultura & Gry', '„Toy Story” z 1995 roku to pierwszy pełnometrażowy film w całości z komputera.', 'Pixar wyprodukował go we współpracy z Disneyem. Przygotowanie obrazu na ekran wymagało ogromnej mocy obliczeniowej.

Reżyser John Lasseter otrzymał za ten film specjalnego Oscara.', 'Wikipedia, „Toy Story”', 'https://en.wikipedia.org/wiki/Toy_Story', '{"question": "Które studio stworzyło „Toy Story”?", "options": ["DreamWorks", "Warner Bros.", "Pixar"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-161', 'Udziały za 800 dolarów', 'Biznes & Pieniądze', 'Trzeci współzałożyciel Apple sprzedał swoje udziały za 800 dolarów.', 'Ronald Wayne miał 10 procent firmy, ale wycofał się po niespełna dwóch tygodniach, w 1976 roku, bojąc się ryzyka.

Tyle udziałów byłoby dziś warte setki miliardów dolarów.', 'Wikipedia, „Ronald Wayne”', 'https://en.wikipedia.org/wiki/Ronald_Wayne', '{"question": "Ile procent Apple miał Ronald Wayne?", "options": ["10", "50", "1"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-162', 'Telefony z papierni', 'Biznes & Pieniądze', 'Nokia zaczynała w 1865 roku jako papiernia w Finlandii.', 'Założył ją inżynier Fredrik Idestam. Nazwa pochodzi od miejscowości, w której działała druga fabryka.

Później firma połączyła się z producentami gumy i kabli. Telefony przyszły dużo później.', 'Wikipedia, „Nokia”', 'https://en.wikipedia.org/wiki/Nokia', '{"question": "Od czego zaczynała się Nokia?", "options": ["Od kabli", "Od papierni", "Od radia"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-163', 'Pięć dolarów dziennie', 'Biznes & Pieniądze', 'Henry Ford w 1914 roku niemal podwoił pensje robotników.', 'Dniówka wzrosła z około 2,34 do 5 dolarów. Fabryka zmagała się z tym, że ludzie masowo odchodzili od taśmy.

Rotacja spadła, a część pracowników mogła odtąd kupić auta, które sama budowała.', 'Wikipedia, „Henry Ford”', 'https://en.wikipedia.org/wiki/Henry_Ford', '{"question": "Jaki problem rozwiązywała podwyżka Forda?", "options": ["Brak stali", "Podatki", "Masowe odejścia pracowników"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-164', 'Cebulka za dom', 'Biznes & Pieniądze', 'W 1637 roku w Holandii rzadkie cebulki tulipanów kosztowały fortunę.', 'Na szczycie gorączki najdroższe odmiany osiągały ponad dziesięciokrotność rocznej pensji rzemieślnika. Potem ceny runęły.

Tulipomania to pierwsza słynna bańka spekulacyjna, choć historycy spierają się o jej realną skalę.', 'Wikipedia, „Tulipomania”', 'https://pl.wikipedia.org/wiki/Tulipomania', '{"question": "Czym stała się tulipomania w historii ekonomii?", "options": ["Słynną bańką spekulacyjną", "Pierwszym podatkiem", "Początkiem giełdy pracy"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-165', 'Aptekarski napój', 'Biznes & Pieniądze', 'Coca-Colę wymyślił w 1886 roku aptekarz z Atlanty.', 'John Pemberton sprzedawał ją w drogerii jako napój z saturatora, po pięć centów za szklankę.

Prawa do receptury przejął później biznesmen Asa Candler i to on zbudował z niej globalną markę.', 'Wikipedia, „Coca-Cola”', 'https://en.wikipedia.org/wiki/Coca-Cola', '{"question": "Kim z zawodu był twórca Coca-Coli?", "options": ["Piekarzem", "Aptekarzem", "Nauczycielem"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-166', 'Prawie Cadabra', 'Biznes & Pieniądze', 'Amazon miał nazywać się Cadabra.', 'Jeff Bezos zarejestrował tę nazwę w 1994 roku, ale prawnik przez telefon usłyszał „cadaver”, czyli zwłoki.

Nową nazwę wybrano po największej rzece świata, a przy okazji zaczynała się na literę A.', 'Wikipedia, „Amazon”', 'https://en.wikipedia.org/wiki/Amazon_(company)', '{"question": "Jak prawnik usłyszał nazwę Cadabra?", "options": ["Jako „kadencja”", "Jako „kolumbia”", "Jako „zwłoki”"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-167', 'Sto bilionów na chleb', 'Biznes & Pieniądze', 'Zimbabwe wydrukowało w 2009 roku banknot o nominale 100 bilionów dolarów.', 'Hiperinflacja była tak wielka, że ceny potrafiły się podwajać co około dobę.

Banknot nie wystarczał na wiele, a kraj porzucił w końcu własną walutę na rzecz obcych.', 'Wikipedia, „Hyperinflation in Zimbabwe”', 'https://en.wikipedia.org/wiki/Hyperinflation_in_Zimbabwe', '{"question": "Co spowodowało druk tak wysokich nominałów?", "options": ["Hiperinflacja", "Odkrycie złota", "Reforma podatkowa"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-168', 'Zapomniany portfel', 'Biznes & Pieniądze', 'Karta Diners Club z 1950 roku miała powstać przez zapomniany portfel.', 'Według firmowej legendy Frank McNamara nie mógł zapłacić w restauracji i wpadł na pomysł karty.

Była z tektury, działała w kilkunastu nowojorskich lokalach i otworzyła drogę dzisiejszym kartom płatniczym.', 'Wikipedia, „Diners Club International”', 'https://en.wikipedia.org/wiki/Diners_Club_International', '{"question": "Z czego była pierwsza karta Diners Club?", "options": ["Z metalu", "Z tektury", "Z plastiku"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-169', 'Oficer z wielorybniczego statku', 'Biznes & Pieniądze', 'Nazwa Starbucks pochodzi z powieści „Moby Dick”.', 'Założyciele szukali morskiego skojarzenia. Odrzucili Pequod, czyli nazwę statku, i wybrali pierwszego oficera, Starbucka.

Morski motyw został też w logo, na którym widnieje dwuogoniasta syrena.', 'Wikipedia, „Starbucks”', 'https://en.wikipedia.org/wiki/Starbucks', '{"question": "Kim jest Starbuck w „Moby Dicku”?", "options": ["Kapitanem", "Kucharzem", "Pierwszym oficerem"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-170', 'Złoty za 1,8 miliona', 'Biznes & Pieniądze', 'W 1924 roku jeden złoty zastąpił 1,8 miliona marek polskich.', 'Reforma premiera Władysława Grabskiego zakończyła hiperinflację po pierwszej wojnie światowej.

Powstał też Bank Polski, który przejął emisję pieniądza.', 'Wikipedia, „Reforma walutowa Władysława Grabskiego”', 'https://pl.wikipedia.org/wiki/Reforma_walutowa_Władysława_Grabskiego', '{"question": "Co zastąpił złoty w 1924 roku?", "options": ["Markę polską", "Rubla", "Koronę"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-171', 'Dlaczego cebula szczypie', 'Zagadki Codzienności', 'Krojona cebula wysyła w stronę oczu drażniący gaz.', 'Nóż uszkadza komórki i uwalnia enzymy, które tworzą lotny związek o nazwie syn-propanotial-S-tlenek.

Gdy dociera do oka, nerwy reagują jak na podrażnienie, a łzy próbują go spłukać.', 'Wikipedia, „Syn-Propanethial-S-oxide”', 'https://en.wikipedia.org/wiki/Syn-Propanethial-S-oxide', '{"question": "Co wywołuje łzy przy krojeniu cebuli?", "options": ["Lotny związek z komórek", "Sok cebuli na palcach", "Ostrość noża"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-172', 'Dlaczego niebo jest niebieskie', 'Zagadki Codzienności', 'Powietrze rozprasza niebieskie światło znacznie silniej niż czerwone.', 'To rozpraszanie Rayleigha: im krótsza fala, tym mocniej odbijają ją cząsteczki powietrza.

O zachodzie światło przechodzi przez grubszą warstwę atmosfery, niebieski ginie po drodze i zostają czerwienie.', 'Wikipedia, „Rozpraszanie Rayleigha”', 'https://pl.wikipedia.org/wiki/Rozpraszanie_Rayleigha', '{"question": "Które światło powietrze rozprasza mocniej?", "options": ["Czerwone", "Niebieskie", "Żółte"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-173', 'Morze w muszli', 'Zagadki Codzienności', 'Szum w muszli to nie morze, tylko dźwięki z otoczenia.', 'Wnętrze muszli działa jak pudło rezonansowe: wzmacnia wybrane częstotliwości cichego hałasu wokół nas.

Podobny szum usłyszysz, przykładając do ucha kubek lub złożoną dłoń.', 'Wikipedia, „Seashell resonance”', 'https://en.wikipedia.org/wiki/Seashell_resonance', '{"question": "Co naprawdę słychać w muszli?", "options": ["Ciśnienie w krwi", "Zapis fal", "Wzmocnione dźwięki otoczenia"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-174', 'Palce po kąpieli', 'Zagadki Codzienności', 'Marszczenie palców w wodzie jest sterowane przez układ nerwowy.', 'Skóra nie nasiąka po prostu wodą: naczynia krwionośne się obkurczają. Przy uszkodzonych nerwach palce się nie marszczą.

Jedna z hipotez mówi, że pomarszczone palce pewniej chwytają mokre przedmioty.', 'Wikipedia, „Wrinkle”', 'https://en.wikipedia.org/wiki/Wrinkle', '{"question": "Co odpowiada za marszczenie palców w wodzie?", "options": ["Układ nerwowy", "Sama woda w skórze", "Temperatura mydła"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-175', 'Trzask kostek', 'Zagadki Codzienności', 'Strzelanie kostkami nie jest łamaniem, tylko efektem gazu w stawie.', 'Rozciąganie stawu obniża ciśnienie w mazi stawowej i powstaje w niej pęcherz gazu. Badanie MRI z 2015 roku pokazało to na żywo.

Badania nie potwierdzają, że ten nawyk powoduje zapalenie stawów.', 'Wikipedia, „Joint cracking”', 'https://en.wikipedia.org/wiki/Joint_cracking', '{"question": "Co powstaje w stawie przy strzelaniu kostkami?", "options": ["Pęknięcie chrząstki", "Pęcherz gazu", "Ciepło"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-176', 'Prawo spadającego tosta', 'Zagadki Codzienności', 'Tost spada zwykle masłem w dół przez wysokość stołu.', 'Fizyk Robert Matthews wykazał, że ze stołu tost zdąży wykonać tylko pół obrotu, więc ląduje na posmarowanej stronie.

Za tę pracę otrzymał w 1996 roku żartobliwą Nagrodę Ig Nobla.', 'Wikipedia, „List of Ig Nobel Prize winners”', 'https://en.wikipedia.org/wiki/List_of_Ig_Nobel_Prize_winners', '{"question": "Co głównie decyduje o lądowaniu tosta?", "options": ["Grubość masła", "Pole magnetyczne", "Wysokość stołu"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-177', 'Księżyc przy horyzoncie', 'Zagadki Codzienności', 'Księżyc nisko nad horyzontem tylko wydaje się większy.', 'Na zdjęciach ma praktycznie tę samą wielkość, co wysoko na niebie. To złudzenie powstaje w mózgu.

Wyjaśnienia wciąż są przedmiotem sporów. Znane jest od starożytności.', 'Wikipedia, „Moon illusion”', 'https://en.wikipedia.org/wiki/Moon_illusion', '{"question": "Gdzie powstaje iluzja większego Księżyca?", "options": ["W mózgu", "W atmosferze", "W obiektywie"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-178', 'Ziewanie się przenosi', 'Zagadki Codzienności', 'Ziewanie bywa zaraźliwe, nawet z człowieka na psa.', 'Wiele osób ziewa, gdy widzi ziewającego, a nawet gdy o tym czyta. Podobną reakcję opisano u szympansów i psów.

Nie ma jednej pewnej odpowiedzi, po co ziewamy. Hipotezy łączą to m.in. z chłodzeniem mózgu i empatią.', 'Wikipedia, „Yawn”', 'https://en.wikipedia.org/wiki/Yawn', '{"question": "Na które zwierzę może przejść ziewanie od człowieka?", "options": ["Na rybę", "Na psa", "Na żółwia"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-179', 'Jak powstaje popcorn', 'Zagadki Codzienności', 'Ziarno kukurydzy eksploduje przez parę uwięzioną w środku.', 'Woda w ziarnie paruje, a twarda łupina trzyma ciśnienie. Pęka przy około 180 stopniach Celsjusza.

Skrobia błyskawicznie wypływa, stygnie i tworzy puszysty kształt.', 'Wikipedia, „Popcorn”', 'https://en.wikipedia.org/wiki/Popcorn', '{"question": "Co rozsadza ziarno popcornu?", "options": ["Tłuszcz", "Sól", "Para wodna"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-180', 'Lustro nie zamienia stron', 'Zagadki Codzienności', 'Lustro nie odwraca lewej i prawej, tylko przód z tyłem.', 'Podnieś prawą rękę: odbicie podniesie rękę po tej samej stronie. Odwrócona jest oś prostopadła do lustra.

Mamy wrażenie zamiany, bo wyobrażamy sobie, że stoimy za szybą i patrzymy w drugą stronę.', 'Wikipedia, „Mirror image”', 'https://en.wikipedia.org/wiki/Mirror_image', '{"question": "Którą oś naprawdę odwraca lustro?", "options": ["Przód i tył", "Górę i dół", "Lewą i prawą"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-181', 'Miód bez daty ważności', 'Ciało & Jedzenie', 'Dobrze przechowywany miód praktycznie się nie psuje.', 'Ma mało wody, jest kwaśny i zawiera dużo cukru, więc bakterie nie mogą się w nim rozwijać.

Archeolodzy znajdowali w starożytnych egipskich grobowcach miód sprzed tysięcy lat.', 'Wikipedia, „Honey”', 'https://en.wikipedia.org/wiki/Honey', '{"question": "Gdzie znajdowano bardzo stary miód?", "options": ["W egipskich grobowcach", "W rzymskich okrętach", "W lodowcach"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-182', 'Kości znikają', 'Ciało & Jedzenie', 'Noworodek ma więcej kości niż dorosły.', 'Niemowlę ma ich około 270, a dorosły 206. Nie giną: z wiekiem wiele się ze sobą zrasta.

Dotyczy to m.in. kości czaszki i kręgosłupa.', 'Wikipedia, „Human skeleton”', 'https://en.wikipedia.org/wiki/Human_skeleton', '{"question": "Ile kości ma dorosły człowiek?", "options": ["106", "206", "306"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-183', 'Banan to jagoda', 'Ciało & Jedzenie', 'Banan jest jagodą w sensie botanicznym, a truskawka nie.', 'Jagoda powstaje z jednego słupka kwiatu i ma nasiona w miękkim miąższu. Tak jest w bananie, pomidorze i winogronie.

Truskawka to owoc rzekomy: mięsista część powstaje z dna kwiatowego, a owocami są żółte pestki.', 'Wikipedia, „Berry (botany)”', 'https://en.wikipedia.org/wiki/Berry_(botany)', '{"question": "Co jest prawdziwymi owocami truskawki?", "options": ["Listki", "Czerwony miąższ", "Żółte pestki"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-184', 'Ptaki nie czują chili', 'Ciało & Jedzenie', 'Dla ptaków papryczki chili wcale nie są ostre.', 'Kapsaicyna działa na receptory ssaków. U ptaków ich odpowiednik na nią nie reaguje.

Taki układ pomaga roślinie, bo ptaki rozsiewają jej nasiona, a ssaki trzyma z daleka.', 'Wikipedia, „Capsaicin”', 'https://en.wikipedia.org/wiki/Capsaicin', '{"question": "Który związek odpowiada za ostrość chili?", "options": ["Kapsaicyna", "Kofeina", "Glukoza"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-185', 'Marchew nie zawsze pomarańczowa', 'Ciało & Jedzenie', 'Dawne uprawne marchwie były często fioletowe lub żółte.', 'Trwałą pomarańczową odmianę wyhodowali Holendrzy, a stała się ona popularna na przełomie XVII i XVIII wieku.

Popularna historia, że wyhodowano je na cześć dynastii Orańskiej, nie ma mocnych dowodów.', 'Wikipedia, „Carrot”', 'https://en.wikipedia.org/wiki/Carrot', '{"question": "Gdzie upowszechniła się pomarańczowa marchew?", "options": ["W Polsce", "W Holandii", "W Japonii"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-186', 'Mózg łasuch', 'Ciało & Jedzenie', 'Mózg to około 2 procent masy ciała, a zużywa 20 procent energii.', 'Spoczynkowy mózg dorosłego człowieka pobiera mniej więcej jedną piątą energii organizmu.

Większość idzie na utrzymanie sygnałów między komórkami nerwowymi. Pracuje nawet we śnie.', 'Wikipedia, „Human brain”', 'https://en.wikipedia.org/wiki/Human_brain', '{"question": "Jaką część energii organizmu zużywa mózg?", "options": ["Około 5 procent", "Około 50 procent", "Około 20 procent"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-187', 'Smak mieszka w nosie', 'Ciało & Jedzenie', 'Większość tego, co nazywamy smakiem, to w istocie zapach.', 'Język rozróżnia tylko kilka smaków podstawowych. Bogactwo aromatów dociera do nosa od strony gardła.

Dlatego przy katarze jedzenie wydaje się mdłe. Zatkaj nos, a trudniej rozpoznasz jogurt po smaku.', 'Wikipedia, „Flavor”', 'https://en.wikipedia.org/wiki/Flavor', '{"question": "Dlaczego jedzenie przy katarze jest mdłe?", "options": ["Nie czujemy zapachów", "Język drętwieje", "Spada cukier"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-188', 'Ketchup z apteki', 'Ciało & Jedzenie', 'W latach 30. XIX wieku ketchup sprzedawano jako lekarstwo.', 'Amerykański lekarz John Cook Bennett przekonywał, że pomidory pomagają przy kłopotach z trawieniem.

Ekstrakt sprzedawano potem jako pigułki pomidorowe, a moda szybko zgasła.', 'Wikipedia, „John C. Bennett”', 'https://en.wikipedia.org/wiki/John_C._Bennett', '{"question": "Jak sprzedawano ketchup w XIX-wiecznej modzie?", "options": ["Jako paliwo", "Jako lekarstwo", "Jako farbę"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-189', 'Długa droga', 'Ciało & Jedzenie', 'Jelito cienkie człowieka ma około sześciu metrów długości.', 'Mieści się w brzuchu, bo jest wielokrotnie pofałdowane.

To tu wchłania się większość składników pokarmu. Fałdy i kosmki bardzo zwiększają jego powierzchnię.', 'Wikipedia, „Small intestine”', 'https://en.wikipedia.org/wiki/Small_intestine', '{"question": "Co zwiększa powierzchnię jelita cienkiego?", "options": ["Tłuszcz", "Włókna mięśni", "Fałdy i kosmki"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-190', 'Sto tysięcy uderzeń', 'Ciało & Jedzenie', 'Serce uderza około 100 tysięcy razy na dobę.', 'Przy spoczynkowym tętnie około 70 uderzeń na minutę daje to ponad 2,5 miliarda skurczów w ciągu długiego życia.

Ma własny rozrusznik: węzeł zatokowy, który wysyła impulsy bez polecenia z mózgu.', 'Wikipedia, „Heart”', 'https://en.wikipedia.org/wiki/Heart', '{"question": "Co wysyła impulsy pobudzające serce?", "options": ["Węzeł zatokowy", "Płuca", "Rdzeń kręgowy"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-191', 'Najwięcej stref czasowych', 'Geografia & Miejsca', 'Rekordzistką stref czasowych jest Francja, nie Rosja.', 'Rosja ma ich 11, ale Francja dzięki terytoriom zamorskim, od Polinezji po Nową Kaledonię, aż 12.

Licząc roszczenia na Antarktydzie, nawet 13.', 'Wikipedia, „Time in France”', 'https://en.wikipedia.org/wiki/Time_in_France', '{"question": "Dlaczego Francja ma tyle stref czasowych?", "options": ["Przez terytoria zamorskie", "Przez ustawę o czasie", "Przez kształt Alp"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-192', 'Kraj mniejszy niż park', 'Geografia & Miejsca', 'Watykan ma tylko około 0,44 kilometra kwadratowego.', 'To najmniejsze państwo świata. Mieści się w całości w Rzymie.

Ma własne znaczki, radio i Gwardię Szwajcarską, a jego mieszkańców jest kilkuset.', 'Wikipedia, „Watykan”', 'https://pl.wikipedia.org/wiki/Watykan', '{"question": "W jakim mieście leży Watykan?", "options": ["W Mediolanie", "W Rzymie", "W Wenecji"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-193', 'Jedna piąta słodkiej wody', 'Geografia & Miejsca', 'Bajkał to najgłębsze jezioro świata, głębokie na ponad 1600 metrów.', 'Syberyjskie jezioro mieści około jednej piątej niezamarzniętej słodkiej wody na powierzchni Ziemi.

Żyje w nim nerpa bajkalska, jedyny gatunek foki spędzający całe życie w słodkiej wodzie.', 'Wikipedia, „Bajkał”', 'https://pl.wikipedia.org/wiki/Bajkał', '{"question": "Jakie zwierzę słynie z życia w Bajkale?", "options": ["Delfin", "Mors", "Foka"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-194', 'Wyżej niż Everest', 'Geografia & Miejsca', 'Punkt najdalszy od środka Ziemi to szczyt Chimborazo, a nie Mount Everest.', 'Ziemia jest spłaszczona i wybrzuszona na równiku. Dlatego ekwadorski wulkan sięga dalej w kosmos, choć mierzy tylko około 6263 metrów.

Everest pozostaje najwyższy licząc od poziomu morza.', 'Wikipedia, „Chimborazo”', 'https://en.wikipedia.org/wiki/Chimborazo', '{"question": "W jakim kraju leży Chimborazo?", "options": ["W Ekwadorze", "W Peru", "W Chile"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-195', 'Góra w oceanie', 'Geografia & Miejsca', 'Mauna Kea liczona od podstawy ma ponad 10 kilometrów.', 'Hawajski wulkan zaczyna się na dnie Pacyfiku, więc większa jego część jest pod wodą.

Nad poziomem morza mierzy około 4207 metrów, ale od podstawy do szczytu wyprzedza Everest.', 'Wikipedia, „Mauna Kea”', 'https://en.wikipedia.org/wiki/Mauna_Kea', '{"question": "Gdzie jest większa część Mauna Kea?", "options": ["W chmurach", "Pod wodą", "Pod lodowcem"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-196', 'Najniżej na lądzie', 'Geografia & Miejsca', 'Brzeg Morza Martwego leży ponad 400 metrów poniżej poziomu morza.', 'To najniższy punkt na lądzie. Woda jest tam prawie dziesięć razy bardziej słona niż w oceanie.

Duże stężenie soli sprawia, że człowiek unosi się na niej bez wysiłku.', 'Wikipedia, „Morze Martwe”', 'https://pl.wikipedia.org/wiki/Morze_Martwe', '{"question": "Dlaczego łatwo unosić się w Morzu Martwym?", "options": ["Woda jest ciepła", "Nie ma fal", "Woda jest bardzo słona"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-197', 'Ziemia niczyja', 'Geografia & Miejsca', 'Bir Tawil to pustynny obszar, którego nie chce żaden kraj.', 'Leży między Egiptem a Sudanem i ma około 2000 kilometrów kwadratowych. Dwa rozbieżne wytyczenia granic stworzyły paradoks.

Oba państwa roszczą sobie prawo do sąsiedniego, cenniejszego trójkąta Halaib, a przyjęcie Bir Tawil oznaczałoby jego utratę.', 'Wikipedia, „Bir Tawil”', 'https://en.wikipedia.org/wiki/Bir_Tawil', '{"question": "Między jakimi krajami leży Bir Tawil?", "options": ["Egiptem i Sudanem", "Libią i Czadem", "Syrią i Irakiem"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-198', 'Kraj w kraju', 'Geografia & Miejsca', 'Lesotho jest w całości otoczone przez Republikę Południowej Afryki.', 'To jedno z zaledwie trzech państw całkowicie otoczonych przez inne. Pozostałe to Watykan i San Marino.

Jest wysoko położone: cały jego teren leży ponad 1000 metrów nad poziomem morza.', 'Wikipedia, „Lesotho”', 'https://en.wikipedia.org/wiki/Lesotho', '{"question": "Które państwo otacza Lesotho?", "options": ["Namibia", "RPA", "Botswana"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-199', 'Miasto na dwóch kontynentach', 'Geografia & Miejsca', 'Stambuł leży jednocześnie w Europie i Azji.', 'Dzieli go cieśnina Bosfor. Mosty łączą obie części, a pod wodą biegnie też tunel kolejowy.

Miasto nazywało się kolejno Bizancjum i Konstantynopol.', 'Wikipedia, „Stambuł”', 'https://pl.wikipedia.org/wiki/Stambuł', '{"question": "Jak nazywa się cieśnina dzieląca Stambuł?", "options": ["Gibraltar", "Skagerrak", "Bosfor"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-200', 'Najdłuższy szyld', 'Geografia & Miejsca', 'Walijska wioska ma w nazwie 58 liter.', 'Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch to w dużej mierze wymysł z XIX wieku, który miał przyciągać turystów.

Mieszkańcy zwykle skracają ją do Llanfairpwll, a stacja kolejowa to atrakcja dla fotografów.', 'Wikipedia, „Llanfairpwllgwyngyll”', 'https://en.wikipedia.org/wiki/Llanfairpwllgwyngyll', '{"question": "Po co wydłużono tę nazwę w XIX wieku?", "options": ["By przyciągać turystów", "By wygrać zakład", "Z powodu ustawy"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-201', 'Podejrzany łosoś', 'Absurdy Prawa', 'W Wielkiej Brytanii zabronione jest obchodzenie się z łososiem w podejrzanych okolicznościach.', 'Tak brzmi nagłówek artykułu 32 ustawy Salmon Act z 1986 roku.

Choć brzmi jak żart, chodzi o coś poważnego: walkę z handlem rybami z kłusownictwa.', 'Wikipedia, „Salmon Act 1986”', 'https://en.wikipedia.org/wiki/Salmon_Act_1986', '{"question": "Czemu naprawdę służy przepis o łososiu?", "options": ["Walce z kłusownictwem", "Ochronie kucharzy", "Regulacji restauracji"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-202', 'Świnka nie może być sama', 'Absurdy Prawa', 'W Szwajcarii nie wolno trzymać pojedynczej świnki morskiej.', 'Przepisy o ochronie zwierząt uznają świnki za zwierzęta stadne, dlatego muszą mieć towarzystwo.

Prawo idzie w tym dalej niż w większości krajów i obejmuje też inne zwierzęta towarzyskie.', 'Wikipedia, „Guinea pig”', 'https://en.wikipedia.org/wiki/Guinea_pig', '{"question": "Dlaczego świnka musi mieć towarzystwo?", "options": ["Bo inaczej ucieka", "Bo to zwierzę stadne", "Bo jest za mała"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-203', 'Mandat od dochodu', 'Absurdy Prawa', 'W Finlandii mandat za prędkość zależy od zarobków.', 'To tzw. dniówki: kara rośnie wraz z dochodem. Menedżer Nokii zapłacił w 2002 roku około 116 tysięcy euro.

System ma sprawić, by kara była równie dotkliwa dla każdego.', 'BBC News, „Nokia boss gets record speeding fine”', 'https://news.bbc.co.uk/2/hi/business/1759791.stm', '{"question": "Jak obliczany jest mandat w Finlandii?", "options": ["Od mocy auta", "Od wieku", "Od dochodu"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-204', 'Dywan przed ósmą', 'Absurdy Prawa', 'W Londynie trzepanie dywanu na ulicy jest zakazane, ale wycieraczki można trzepać przed ósmą.', 'Przepis pochodzi z ustawy Metropolitan Police Act z 1839 roku, która wylicza dziesiątki uciążliwych zachowań.

Wiele z nich brzmi dziś jak ciekawostka z innej epoki.', 'Metropolitan Police Act 1839, art. 60', 'https://www.legislation.gov.uk/ukpga/Vict/2-3/47/section/60', '{"question": "Co wolno trzepać w Londynie przed ósmą?", "options": ["Wycieraczkę", "Dywan", "Kołdrę"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-205', 'Nietrzeźwy z krową', 'Absurdy Prawa', 'Brytyjska ustawa zabrania bycia pijanym, gdy prowadzi się bydło.', 'Licensing Act z 1872 roku karze nietrzeźwość w miejscu publicznym, także w czasie opieki nad koniem, bydłem czy powozem.

Przepis wciąż obowiązuje, choć dziś rzadko kto prowadzi bydło ulicą.', 'Wikipedia, „Licensing Act 1872”', 'https://en.wikipedia.org/wiki/Licensing_Act_1872', '{"question": "Z którego roku jest ta ustawa?", "options": ["1972", "1872", "1772"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-206', 'Zakaz umierania', 'Absurdy Prawa', 'Burmistrz francuskiego Le Lavandou zakazał w 2000 roku umierania na terenie miasta.', 'Gil Bernardi protestował tak przeciw decyzji sądu, która zablokowała budowę nowego cmentarza.

Zakaz nie był egzekwowany, a miał zwrócić uwagę na brak miejsc pochówku.', 'Wikipedia, „Le Lavandou”', 'https://en.wikipedia.org/wiki/Le_Lavandou', '{"question": "Czego zabrakło w Le Lavandou?", "options": ["Burmistrza", "Lekarzy", "Miejsc na cmentarzu"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-207', 'Obwód pod kontrolą', 'Absurdy Prawa', 'W Japonii firmy i samorządy mierzą obwód pasa dorosłych.', 'Prawo z 2008 roku, zwane ustawą metabo, obejmuje osoby od 40 do 74 lat podczas corocznych badań.

Kto przekroczy limit, dostaje porady zdrowotne, a kary finansowe dotykają firm i samorządów, nie pacjentów.', 'Wikipedia, „Fat tax”', 'https://en.wikipedia.org/wiki/Fat_tax', '{"question": "Kto ponosi kary w ustawie metabo?", "options": ["Firmy i samorządy", "Pacjenci", "Lekarze"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-208', 'Imię do zatwierdzenia', 'Absurdy Prawa', 'Na Islandii specjalny komitet decyduje, czy imię jest dozwolone.', 'Komitet nazewniczy sprawdza, czy imię pasuje do języka islandzkiego i jego gramatyki.

Bywają spory: w 2013 roku dziewczynka o imieniu Blær wygrała sprawę w sądzie po latach zapisywania jej jako „dziewczynka”.', 'Wikipedia, „Icelandic Naming Committee”', 'https://en.wikipedia.org/wiki/Icelandic_Naming_Committee', '{"question": "Kto decyduje o imionach na Islandii?", "options": ["Prezydent", "Specjalny komitet", "Kościół"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-209', 'Liczba pi z ustawy', 'Absurdy Prawa', 'W 1897 roku stan Indiana prawie ustawowo zmienił wartość liczby pi.', 'Lekarz i matematyk amator Edward Goodwin twierdził, że rozwiązał kwadraturę koła. Izba niższa przyjęła projekt jednogłośnie.

W senacie zatrzymał go przypadkiem przebywający tam matematyk, profesor C. A. Waldo.', 'Wikipedia, „Indiana pi bill”', 'https://en.wikipedia.org/wiki/Indiana_pi_bill', '{"question": "Kto powstrzymał ustawę o pi?", "options": ["Gubernator", "Papież", "Matematyk"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-210', 'Bez zbroi w parlamencie', 'Absurdy Prawa', 'W brytyjskim parlamencie obowiązuje zakaz noszenia zbroi z 1313 roku.', 'Statut wydany za Edwarda II miał zapobiec zbrojnym zamieszkom podczas obrad.

Formalnie nadal obowiązuje, choć raczej nikt go dziś nie narusza.', 'Wikipedia, „Statute forbidding Bearing of Armour”', 'https://en.wikipedia.org/wiki/Statute_forbidding_Bearing_of_Armour', '{"question": "Za którego króla wydano ten zakaz?", "options": ["Za Edwarda II", "Za Henryka VIII", "Za Jerzego III"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-211', 'Małpa czy ślimak', 'Język & Symbole', 'Znak @ w wielu krajach ma zupełnie inną nazwę.', 'W Polsce to małpa, we Włoszech ślimak, a w Holandii małpi ogon.

Do adresów e-mail wybrał go w 1971 roku Ray Tomlinson, bo prawie nie pojawiał się w imionach.', 'Wikipedia, „Małpa (znak pisarski)”', 'https://pl.wikipedia.org/wiki/Małpa_(znak_pisarski)', '{"question": "Jak Włosi nazywają znak @?", "options": ["Ślimak", "Kot", "Łabędź"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-212', 'Zanim był hashtag', 'Język & Symbole', 'Hashtagi wymyślił użytkownik Twittera, nie firma.', 'W 2007 roku Chris Messina zaproponował znak # do grupowania wpisów. Twitter początkowo nie był zachwycony.

Fachowa nazwa znaku to oktotorp.', 'Wikipedia, „Hashtag”', 'https://en.wikipedia.org/wiki/Hashtag', '{"question": "Kto zaproponował hashtagi?", "options": ["Założyciel Twittera", "Użytkownik Chris Messina", "Mark Zuckerberg"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-213', 'Ukryte litery', 'Język & Symbole', 'Znak & to w rzeczywistości łacińskie słowo „et”.', 'Ampersand powstał jako połączenie liter e i t, czyli „i” po łacinie. W wielu krojach pisma nadal to widać.

Nazwa pochodzi od angielskiej recytacji alfabetu: „and per se and”.', 'Wikipedia, „Ampersand”', 'https://en.wikipedia.org/wiki/Ampersand', '{"question": "Jakie słowo kryje się w znaku &?", "options": ["Sed", "Ad", "Et"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-214', 'Skrót z żartu', 'Język & Symbole', 'OK zaczęło się od celowej literówki w gazecie z 1839 roku.', 'W Bostonie modne były zabawne skróty. „O.K.” oznaczało „oll korrect”, czyli błędnie zapisane „all correct”.

Historię tę odtworzył językoznawca Allen Walker Read.', 'Wikipedia, „OK”', 'https://en.wikipedia.org/wiki/OK', '{"question": "Co oznaczał skrót O.K. w gazecie?", "options": ["Oll korrect", "Old king", "Only kindness"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-215', 'Emotikony z Japonii', 'Język & Symbole', 'Za ojca emoji uchodzi Japończyk, który narysował 176 ikonek.', 'Shigetaka Kurita przygotował je około 1999 roku dla mobilnego serwisu firmy NTT DoCoMo. Każda mieściła się w siatce 12 na 12 pikseli.

Dziś zestaw jest w kolekcji nowojorskiego Museum of Modern Art.', 'Wikipedia, „Emoji”', 'https://en.wikipedia.org/wiki/Emoji', '{"question": "Ile ikonek miał zestaw Kurity?", "options": ["17", "176", "1760"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-216', 'Król w słuchawkach', 'Język & Symbole', 'Bluetooth nosi przydomek duńskiego króla z X wieku.', 'Harald Sinozęby zjednoczył plemiona Danii, tak jak technologia miała łączyć urządzenia.

Logo to połączenie run oznaczających jego inicjały: H i B.', 'Wikipedia, „Bluetooth”', 'https://en.wikipedia.org/wiki/Bluetooth', '{"question": "Co przedstawia logo Bluetooth?", "options": ["Fale radiowe", "Literę B i błyskawicę", "Połączone runy"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-217', 'Jedynka i zero', 'Język & Symbole', 'Symbol zasilania to połączone znaki 1 i 0.', 'Kreska oznacza włączenie, a okrąg wyłączenie. To skrót z zapisu dwójkowego, standaryzowany przez międzynarodową komisję elektrotechniczną.

Kółko z kreską w środku oznacza stan czuwania.', 'Wikipedia, „Power symbol”', 'https://en.wikipedia.org/wiki/Power_symbol', '{"question": "Co oznacza kreska w symbolu zasilania?", "options": ["Włączenie", "Baterię", "Wyłączenie"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-218', 'Zdanie ze wszystkich liter', 'Język & Symbole', 'Pangram to zdanie, w którym są wszystkie litery alfabetu.', 'Polskim klasykiem jest: „Pchnąć w tę łódź jeża lub ośm skrzyń fig”.

Takie zdania służą do pokazywania krojów pisma i sprawdzania klawiatur.', 'Wikipedia, „Pangram”', 'https://pl.wikipedia.org/wiki/Pangram', '{"question": "Do czego używa się pangramów?", "options": ["Do szyfrowania", "Do pokazywania krojów pisma", "Do nauki tabliczki mnożenia"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-219', 'Robot pochodzi ze słowiańskiego', 'Język & Symbole', 'Słowo „robot” pochodzi z czeskiej sztuki z 1920 roku.', 'Karel Čapek użył go w dramacie „R.U.R.”. Podsunął je podobno jego brat Josef.

Słowo wywodzi się od „roboty”, czyli przymusowej pracy.', 'Wikipedia, „Robot”', 'https://pl.wikipedia.org/wiki/Robot', '{"question": "Kto użył słowa „robot” w sztuce?", "options": ["Stanisław Lem", "Isaac Asimov", "Karel Čapek"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-220', 'Znak pokoju z semafora', 'Język & Symbole', 'Znak pokoju to litery N i D zapisane alfabetem chorągiewkowym.', 'Gerald Holtom zaprojektował go w 1958 roku dla brytyjskiego ruchu przeciw broni atomowej.

Litery to skrót od „nuclear disarmament”, czyli rozbrojenie nuklearne. Znak nigdy nie został opatentowany.', 'Wikipedia, „Peace symbols”', 'https://en.wikipedia.org/wiki/Peace_symbols', '{"question": "Skrótem czego są litery N i D?", "options": ["Rozbrojenia nuklearnego", "Nowego porządku", "Pokojowego marszu"], "correctIndex": 0}'::jsonb, 'published')
on conflict (id) do nothing;
