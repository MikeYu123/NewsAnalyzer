#encoding "utf-8"
//IDEA: использовать словарь?
Country -> Noun<h-reg1>; //Россия, Канада, ....
Country -> Adj<h-reg1, gnc-agr[1]>+ Noun<h-reg1, gnc-agr[1], rt>; //Российская Федерация, Саудовская Аравия
// //IDEA: h-reg3?
Country -> Noun<h-reg2>; //США, КНДР...
// Country -> Adj<h-reg1>+ Word<kwtype="постфикс_страна">;

Region -> Adj<h-reg1> Word<kwtype="постфикс_регион">;
Region -> Word<kwtype="префикс_регион", gnc-agr[1]> Noun<h-reg1, gnc-agr[1]>;
Subregion -> Adj<h-reg1> Word<kwtype="постфикс_подрегион">;
// City -> Noun<h-reg1>; // TODO: collision with Country
City -> Word<kwtype="префикс_город", gnc-agr[1]> Noun<h-reg1, gnc-agr[1]>;

Place -> Country interp (Place.Country);
Place -> Region interp (Place.Region);
Place -> Subregion interp (Place.Subregion);
Place -> City interp (Place.City);
