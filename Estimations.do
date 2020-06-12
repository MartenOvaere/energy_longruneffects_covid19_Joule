set more off
set matsize 10000

* enter your directory here
cd "C:\Users\mo524\Dropbox (Yale_FES)\Covid_19\JOULE_FINAL_SUBMISSION\Code_data" 

//GASOLINE and KEROSINE
import excel using oil_data,clear firstrow
gen year = year(Date)
gen week = week(Date)
gen elapweeks = _n
gen elapweeks2 = elapweeks^2
gen elapweeks3 = elapweeks^3
gen elapweeks4 = elapweeks^4
gen covid=1 if elapweeks>=1534
replace covid=0 if elapweeks<1534
drop if year<2001

//ESTIMATION
gen energy_decrease = .
gen baseline_energy_decrease = .
gen energy_decrease_ci_high = .
gen energy_decrease_ci_low = .
gen energy_decrease2 = .
gen energy_decrease_ci_high2 = .
gen energy_decrease_ci_low2 = .
local index = 1
foreach oil in gasoline kerosene { 
reg `oil' covid i.week elapweeks elapweeks2 elapweeks3 elapweeks4
qui reg `oil' i.week if year<= 2019
predict `oil'_hat, xb
gen delta_`oil'_hat = `oil'-`oil'_hat
reg delta_`oil'_hat covid elapweeks if year>=2020 & (week<11 | week>=13)
reg delta_`oil'_hat covid if year>=2020 & (week<11 | week>=13)
ereturn list
matrix A = e(b)
replace energy_decrease2 = A[1,1] in `index'
replace energy_decrease_ci_low2 = A[1,1] - invttail(e(df_r),0.025)*_se[covid] in `index'
replace energy_decrease_ci_high2 = A[1,1] + invttail(e(df_r),0.025)*_se[covid] in `index'
ci means delta_`oil'_hat if year>=2020 &  week>=13, level(95) 
replace energy_decrease = r(mean) in `index'
replace energy_decrease_ci_low = r(lb)  in `index'
replace energy_decrease_ci_high = r(ub) in `index'
mean `oil' if year==2019 & (week>=13 & week<=22)
ereturn list
matrix A = e(b)
replace baseline_energy_decrease = A[1,1] in `index'
local index=`index'+1

//FIGURES
preserve
replace `oil'=`oil'/1000
qui reg `oil' i.week elapweeks elapweeks2 elapweeks3 elapweeks4 if year>2011 & year<=2019
predict `oil'_hat2, xb
predict error, stdp
gen `oil'_hat_lb = `oil'_hat2 - invnormal(0.995)*error
gen `oil'_hat_ub = `oil'_hat2 + invnormal(0.995)*error
graph twoway (rarea `oil'_hat_lb `oil'_hat_ub Date if year>=2019, color(gs12)) (line `oil' Date if year>=2019, lwidth(thick) lcolor(black)), xline(21994, lwidth(thick)) tscale(range(01jan2019 10jul2020)) ///
xtitle(Time) legend(row(2) order(2 "Actual `oil' consumption" 1 "99% Confidence interval of predicted `oil' consumption") region(lcolor(white))) graphregion(color(white)) bgcolor(white) ytitle("U.S. `oil' consumption (MBBD)")
graph export `oil'_timeseries.eps, replace 
graph export `oil'_timeseries.png, replace
drop error
restore
}

foreach oil in total_oil { 
//FIGURES
replace `oil'=`oil'/1000
qui reg `oil' i.week elapweeks elapweeks2 elapweeks3 elapweeks4 if year>2011 & year<=2019
predict `oil'_hat3, xb
predict error, stdp
gen `oil'_hat_lb = `oil'_hat3 - invnormal(0.995)*error
gen `oil'_hat_ub = `oil'_hat3 + invnormal(0.995)*error
graph twoway (line `oil'_hat3 Date if year>=2019, color(black) lpattern(dash)) (line `oil' Date if year>=2019, lwidth(thick) lcolor(black)),  xline(21994, lwidth(thick)) tscale(range(01jan2019 10jul2020)) ///
xtitle(Time) legend(row(2) order(2 "Actual total oil consumption" 1 "Predicted total oil consumption") region(lcolor(white))) ///
graphregion(color(white)) bgcolor(white) ytitle("U.S. total oil consumption (MBBD)") note("Note: Total oil consumption includes gasoline, kerosene, propane, propylene, distillate fuel" "oil, residual fuel oil, and other oils.")
graph export `oil'_timeseries.eps, replace 
drop error
}

replace total_oil=total_oil*1000
gen other_oil = total_oil - kerosene - gasoline
foreach oil in other_oil { 
//FIGURES
replace `oil'=`oil'/1000
qui reg `oil' i.week elapweeks elapweeks2 elapweeks3 elapweeks4 if year>2011 & year<=2019
predict `oil'_hat3, xb
predict error, stdp
gen `oil'_hat_lb = `oil'_hat3 - invnormal(0.995)*error
gen `oil'_hat_ub = `oil'_hat3 + invnormal(0.995)*error
graph twoway (rarea `oil'_hat_lb `oil'_hat_ub Date if year>=2019, color(gs12)) (line `oil' Date if year>=2019, lwidth(thick) lcolor(black)),  xline(21994, lwidth(thick)) tscale(range(01jan2019 10jul2020)) ///
xtitle(Time) legend(row(2) order(2 "Actual non-gasoline and - kerosene consumption" 1 "Predicted non-gasoline and - kerosene consumption") region(lcolor(white))) ///
graphregion(color(white)) bgcolor(white) ytitle("U.S. total oil consumption (MBBD)") note("Note: Includes propane, propylene, distillate fuel oil, residual fuel oil, and other oils.")
graph export `oil'_timeseries.eps, replace 
graph export `oil'_timeseries.png, replace
drop error
}

gen yearly_demand_temp = sum(gasoline)/52 if year==2019
egen yearly_demand_temp2 = max(yearly_demand_temp) //MBB
replace yearly_demand_temp = sum(kerosene)/52 if year==2019
egen yearly_demand_temp3 = max(yearly_demand_temp) //MBB
gen yearly_demand = yearly_demand_temp2/1000 in 1
replace yearly_demand = yearly_demand_temp3/1000 in 2
preserve
keep baseline_energy_decrease energy_decrease* yearly_demand
gen label = "Motor gasoline" in 1
replace label = "Jet fuel" in 2
drop if energy_decrease==.
save results_oil,replace
restore

************************************************************************
//COAL
import excel using data_coal,clear firstrow
gen elapweeks = _n
gen covid=1 if elapweeks>=534
replace covid=0 if elapweeks<534
gen Date = yw(year,week)
format Date %tw

//ESTIMATION
reg coal_production covid i.week elapweeks
ereturn list
matrix A = e(b)
gen energy_decrease = A[1,1] in 1
gen energy_decrease_ci_low = .  in 1
gen energy_decrease_ci_high = . in 1
mean coal_production if year==2019 & (week>=13 & week<=15)
ereturn list
matrix A = e(b)
gen baseline_energy_decrease = A[1,1] in 1
preserve
keep baseline_energy_decrease energy_decrease*
gen label = "Coal production" in 1
drop if energy_decrease==.
save results_coal,replace
restore

//FIGURES
qui reg coal_production i.week elapweeks
predict coal_production_hat2, xb
predict coal_error, stdp
gen coal_hat_lb = coal_production_hat2 - invnormal(0.995)*coal_error
gen coal_hat_ub = coal_production_hat2 + invnormal(0.995)*coal_error
graph twoway (rarea coal_hat_lb coal_hat_ub Date if elapweeks>470, color(gs12)) (line coal_production Date if elapweeks>470, xline(22001, lwidth(thick)) lwidth(thick) lcolor(black)) ///
,  xtitle(Time) legend(row(2) order(2 "Actual coal production" 1 "99% Confidence interval of predicted coal production") region(lcolor(white))) graphregion(color(white)) bgcolor(white) ytitle("U.S. daily residential + commercial natural gas consumption [Bcf per day]")
graph export Coal_timeseries.eps, replace
graph export Coal_timeseries.png, replace

************************************************************************
//GAS
import excel using gas_data,clear firstrow
drop if year<2017
gen elapweeks = _n
gen covid=1 if elapweeks>=169
replace covid=0 if elapweeks<169
gen year_end = year(end_week)
gen month_end = month(end_week)
gen day_end = day(end_week)
save gas_data, replace
merge m:1 month_end day_end year_end using hdd_gas_heating
keep if _merge == 3
drop _merge
merge m:1 month_end day_end year_end using cdd_population
keep if _merge == 3
drop _merge
merge m:1 month_end day_end year_end using hdd_elec_heating
keep if _merge == 3
drop _merge
sort end_week
gen elapweeks2 = elapweeks^2
gen elapweeks3 = elapweeks^3
gen elapweeks4 = elapweeks^4

//ESTIMATION
gen energy_decrease = .
gen baseline_energy_decrease = .
gen energy_decrease_ci_low = .
gen energy_decrease_ci_high = .
gen energy_decrease2 = .
gen energy_decrease_ci_low2 = .
gen energy_decrease_ci_high2 = .
local index = 1
foreach cons in residential power industrial usa { // 
//Global polynomial
reg gas_`cons' i.covid elapweeks elapweeks2 hdd_gas_heating_week cdd_population_week elapweeks3 elapweeks4 
//Augmented local
qui reg gas_`cons' elapweeks hdd_gas_heating_week cdd_population_week if elapweeks<165
predict gas_`cons'_hat, xb
gen delta_gas_`cons'_hat = gas_`cons'-gas_`cons'_hat
reg delta_gas_`cons'_hat covid elapweeks if year>=2020 & (week<11 | week>=13)
reg delta_gas_`cons'_hat covid if year>=2020 & (week<11 | week>=13)
ereturn list
matrix A = e(b)
replace energy_decrease = A[1,1] in `index'
replace energy_decrease_ci_low = A[1,1] - invttail(e(df_r),0.025)*_se[covid] in `index'
replace energy_decrease_ci_high = A[1,1] + invttail(e(df_r),0.025)*_se[covid] in `index'
ci means delta_gas_`cons'_hat if year>=2020 & week>=13, level(95)
replace energy_decrease2 = r(mean) in `index'
replace energy_decrease_ci_low2= r(lb)  in `index'
replace energy_decrease_ci_high2 = r(ub) in `index'
mean gas_`cons' if year==2019 & (week>=13 & week<=22)
ereturn list
matrix A = e(b)
replace baseline_energy_decrease = A[1,1] in `index'
local index=`index'+1
}
egen yearly_demand_temp = mean(gas_usa) if year==2019
egen yearly_demand_temp2 = max(yearly_demand_temp)
gen yearly_demand = yearly_demand_temp2/1000 in 1

preserve
keep baseline_energy_decrease energy_decrease* yearly_demand
gen label = "Natural gas res.+com." in 1
replace label = "Natural gas power" in 2
replace label = "Natural gas industrial" in 3
replace label = "Natural gas total" in 4
drop if energy_decrease==.
save results_gas,replace
restore

//FIGURES
qui reg gas_residential elapweeks hdd_gas_heating_week cdd_population_week elapweeks2 elapweeks3 elapweeks4 if elapweeks<165
predict gas_residential_hat2, xb
predict gas_residential_hat_error, stdp
gen gas_residential_hat_lb = gas_residential_hat2 - invnormal(0.995)*gas_residential_hat_error
gen gas_residential_hat_ub = gas_residential_hat2 + invnormal(0.995)*gas_residential_hat_error
graph twoway (rarea gas_residential_hat_lb gas_residential_hat_ub end_week if year>=2019, color(gs12)) (line gas_residential end_week if year>=2019, lwidth(thick) lcolor(black)),  xline(21994, lwidth(thick)) xtitle(Time) legend(row(2) order(2 "Actual residential and commercial natural gas consumption" 1 "99% CI of predicted res. and com. natural gas consumption") region(lcolor(white))) graphregion(color(white)) bgcolor(white) ytitle("U.S. daily residential + commercial natural gas consumption [Bcf per day]")
graph export Gas_residential_timeseries.eps, replace
graph export Gas_residential_timeseries.png, replace

foreach tech in industrial power {
qui reg gas_`tech' elapweeks hdd_gas_heating_week cdd_population_week elapweeks2 elapweeks3 elapweeks4 if elapweeks<165
predict gas_`tech'_hat2, xb
predict gas_`tech'_hat_error, stdp
gen gas_`tech'_hat_lb = gas_`tech'_hat2 - invnormal(0.995)*gas_`tech'_hat_error
gen gas_`tech'_hat_ub = gas_`tech'_hat2 + invnormal(0.995)*gas_`tech'_hat_error
graph twoway (rarea gas_`tech'_hat_lb gas_`tech'_hat_ub end_week if year>=2019, color(gs12)) (line gas_`tech' end_week if year>=2019, lwidth(thick) lcolor(black)),  xline(21994, lwidth(thick)) xtitle(Time) legend(row(2) order(2 "Actual `tech' natural gas consumption" 1 "99% CI of predicted `tech' natural gas consumption") region(lcolor(white))) graphregion(color(white)) bgcolor(white) ytitle("U.S. daily `tech' natural gas consumption [Bcf per day]")
graph export Gas_`tech'_timeseries.eps, replace
graph export Gas_`tech'_timeseries.png, replace
}

qui reg gas_usa elapweeks hdd_gas_heating_week cdd_population_week elapweeks2 elapweeks3 elapweeks4 if elapweeks<165
predict gas_usa_hat2, xb
predict gas_usa_hat_error, stdp
gen gas_usa_hat_lb = gas_usa_hat2 - invnormal(0.995)*gas_usa_hat_error
gen gas_usa_hat_ub = gas_usa_hat2 + invnormal(0.995)*gas_usa_hat_error
graph twoway (rarea gas_usa_hat_lb gas_usa_hat_ub end_week if year>=2019, color(gs12)) (line gas_usa end_week if year>=2019, lwidth(thick) lcolor(black)), xline(21994, lwidth(thick)) xtitle(Time) legend(row(2) order(2 "Actual total natural gas consumption" 1 "99% CI of predicted total natural gas consumption") region(lcolor(white))) graphregion(color(white)) bgcolor(white) ytitle("U.S. daily total natural gas consumption [Bcf per day]")
graph export Gas_usa_timeseries.eps, replace
graph export Gas_usa_timeseries.png, replace

************************************************************************
//ELECTRICITY
import excel using load_usa,clear firstrow
gen date2 = dofc(date)
format date2 %td
gen year = year(date2)
gen month = month(date2)
gen day = day(date2)
collapse (mean) load* gen* (first) date2, by(year month day)
gen elapdays = _n
gen covid=1 if elapdays>=1731
replace covid=0 if elapdays<1731
ren month month_end
ren day day_end
ren year year_end
gen elapdays2 = elapdays^2
gen elapdays3 = elapdays^3
gen elapdays4 = elapdays^4

merge m:1 year_end month_end day_end using hdd_gas_heating
keep if _merge == 3
drop _merge
merge m:1 year_end month_end day_end using cdd_population
keep if _merge == 3
drop _merge
merge m:1 year_end month_end day_end using hdd_elec_heating
keep if _merge == 3
drop _merge

//ESTIMATION
reg load_usa covid elapdays elapdays2 elapdays3 elapdays4 hdd_gas_heating_week hdd_elec_heating_week cdd_population if year>=2017
qui reg load_usa elapdays hdd_gas_heating_week hdd_elec_heating_week cdd_population if year>=2019 & elapdays<1717
predict load_hat, xb
gen delta_load_hat = load_usa-load_hat
reg delta_load_hat covid elapdays if year>=2020 & (elapdays<1717 | elapdays>=1731)
reg delta_load_hat covid if year>=2020 & (elapdays<1717 | elapdays>=1731)
ereturn list
matrix A = e(b)
gen energy_decrease2 = A[1,1] in 1
gen energy_decrease_ci_low2 = A[1,1] - invttail(e(df_r),0.025)*_se[covid] in 1
gen energy_decrease_ci_high2 = A[1,1] + invttail(e(df_r),0.025)*_se[covid] in 1
ci means delta_load_hat if elapdays>=1731, level(95)
gen energy_decrease = r(mean) in 1
gen energy_decrease_ci_low = r(lb)  in 1
gen energy_decrease_ci_high = r(ub) in 1
mean load_usa if year<2020 & ((month_end==3 & day_end>=25) | (month_end==4) | month_end==5 | (month_end==6 & day_end<=8))

ereturn list
matrix A = e(b)
gen baseline_energy_decrease = A[1,1] in 1

sort date2
gen gen_sum = 0
local index = 2
foreach tech in gas coal other oil hydro nuclear { //
di "`tech'"
di "`index'" 
reg gen_`tech'_usa covid elapdays elapdays2 elapdays3 elapdays4 gen_wind_usa gen_solar_usa hdd_gas_heating_week hdd_elec_heating_week cdd_population if year>=2019 //
qui reg gen_`tech'_usa elapdays gen_wind_usa gen_solar_usa hdd_gas_heating_week hdd_elec_heating_week cdd_population if year>=2019 & elapdays<1717
predict gen_`tech'_hat, xb
gen delta_gen_`tech'_hat = gen_`tech'_usa-gen_`tech'_hat
reg delta_gen_`tech'_hat covid elapdays if year>=2020 & (elapdays<1717 | elapdays>=1731)
reg delta_gen_`tech'_hat covid if year>=2020 & (elapdays<1717 | elapdays>=1731) 
ereturn list
matrix A = e(b)
replace energy_decrease2 = A[1,1] in `index'
replace energy_decrease_ci_low2 = A[1,1] - invttail(e(df_r),0.025)*_se[covid] in `index'
replace energy_decrease_ci_high2 = A[1,1] + invttail(e(df_r),0.025)*_se[covid] in `index'
ci means delta_gen_`tech'_hat if elapdays>=1731, level(95)
replace energy_decrease = r(mean) in `index'
replace energy_decrease_ci_low = r(lb)  in `index'
replace energy_decrease_ci_high = r(ub) in `index'
mean gen_`tech'_usa if year==2019 & ((month_end==3 & day_end>=25) | (month_end==4) | month_end==5 | (month_end==6 & day_end<=8))
ereturn list
matrix A = e(b)
replace baseline_energy_decrease = A[1,1] in `index'
replace gen_sum = gen_sum + gen_`tech'_usa
local index=`index'+1
}

replace gen_sum = gen_sum + gen_solar_usa + gen_wind_usa if year>=2019
gen add_load = load_usa-gen_sum  if year>=2019
reg add_load covid elapdays  if year>=2019

preserve
keep baseline_energy_decrease energy_decrease*
gen label = "Electricity demand" in 1
replace label = "Gas-fired electricity" in 2
replace label = "Coal-fired electricity" in 3
replace label = "Electricity_other" in 4
replace label = "Electricity_oil" in 5
replace label = "Electricity_hydro" in 6
replace label = "Electricity_nuclear" in 7

drop if energy_decrease==.
save results_electricity,replace
restore

gen week=wofd(date2)
//FIGURES
foreach tech in gas coal nuclear  { 
preserve
replace gen_`tech'_usa = gen_`tech'_usa/1000
reg gen_`tech'_usa elapdays gen_wind_usa gen_solar_usa cdd_population_week  hdd_gas_heating_week hdd_elec_heating_week if year>=2019 & elapdays<1717 
predict gen_`tech'_usa_hat, xb
predict gen_`tech'_usa_hat_error, stdp
gen gen_`tech'_usa_hat_lb = gen_`tech'_usa_hat - invnormal(0.995)*gen_`tech'_usa_hat_error
gen gen_`tech'_usa_hat_ub = gen_`tech'_usa_hat + invnormal(0.995)*gen_`tech'_usa_hat_error
collapse (mean) gen_* hdd* cdd* load* (first) year elapdays date2, by(week)
graph twoway (rarea gen_`tech'_usa_hat_lb gen_`tech'_usa_hat_ub date2 if year>=2019, color(gs12)) (line gen_`tech'_usa date2 if year>=2019, lwidth(thick) lcolor(black)), xline(21994, lwidth(thick)) xtitle(Time) legend(row(2) order(2 "Actual `tech'-fired electricity generation" 1 "99% CI of predicted `tech'-fired electricity generation") region(lcolor(white))) graphregion(color(white)) bgcolor(white) ytitle("U.S. `tech'-fired electricity generation [GW]")
graph export gen_`tech'_usa_timeseries.eps, replace
graph export gen_`tech'_usa_timeseries.png, replace
restore
}

preserve
qui reg load_usa elapdays gen_wind_usa gen_solar_usa hdd_gas_heating_week hdd_elec_heating_week cdd_population_week if year>=2019 & elapdays<1717
predict load_usa_hat, xb
predict load_usa_hat_error, stdp
gen load_usa_hat_lb = load_usa_hat - invnormal(0.995)*load_usa_hat_error
gen load_usa_hat_ub = load_usa_hat + invnormal(0.995)*load_usa_hat_error
collapse (mean) gen_* hdd* cdd* load* (first) year elapdays date2, by(week)
graph twoway (rarea load_usa_hat_lb load_usa_hat_ub date2 if year>=2019, color(gs12)) (line load_usa date2 if year>=2019, lwidth(thick) lcolor(black)), xline(21994, lwidth(thick)) xtitle(Time) legend(row(2) order(2 "Actual electricity demand" 1 "99% CI of predicted electricity demand") region(lcolor(white))) graphregion(color(white)) bgcolor(white) ytitle("U.S. electricity demand [MW]")
graph export load_usa_timeseries.eps, replace
restore

//FIGURE LOAD
preserve
replace load_usa = load_usa/1000
qui reg load_usa elapdays gen_wind_usa gen_solar_usa hdd_gas_heating_week hdd_elec_heating_week cdd_population_week if year>=2017 & elapdays<1717
predict load_usa_hat, xb
collapse (mean) gen_* hdd* cdd* load* (first) year elapdays date2, by(week)
graph twoway (line load_usa_hat date2 if year>=2019, color(black) lpattern(dash)) (line load_usa date2 if year>=2019, lwidth(thick) lcolor(black)), xline(21994, lwidth(thick)) tscale(range(01jan2019 10jul2020)) ///
xtitle(Time)legend(row(2) order(2 "Actual electricity demand" 1 "Predicted electricity demand") region(lcolor(white))) graphregion(color(white)) bgcolor(white) ytitle("U.S. weekly-average electricity demand [GW]")
graph export load_usa_timeseries_final.eps, replace
graph export load_usa_timeseries_final.emf, replace 
restore

************************************************************************
//MERGE RESULTS
use results_oil, clear
append using results_coal
append using results_gas
append using results_electricity
replace energy_decrease = -1*energy_decrease
replace energy_decrease_ci_high = -1*energy_decrease_ci_high
replace energy_decrease_ci_low = -1*energy_decrease_ci_low
replace energy_decrease = energy_decrease/1000 in 1/2 // MMBD
replace baseline_energy_decrease = baseline_energy_decrease/1000 in 1/2 // MMBD
replace energy_decrease_ci_high = energy_decrease_ci_high/1000 in 1/2 // MMBD
replace energy_decrease_ci_low = energy_decrease_ci_low/1000 in 1/2 // MMBD
replace energy_decrease = energy_decrease/1.10231/7/1000000 in 3 //short ton per week to million metric ton per day
replace baseline_energy_decrease = baseline_energy_decrease/1.10231/7/1000000 in 3 //short ton per week to million metric ton per day
replace energy_decrease_ci_high = energy_decrease_ci_high/1.10231/7/1000000 in 3 //short ton per week to million metric ton per day
replace energy_decrease_ci_low = energy_decrease_ci_low/1.10231/7/1000000 in 3 //short ton per week to million metric ton per day
replace energy_decrease = energy_decrease*24/1000000 in 8/14 //MW to TWh
replace baseline_energy_decrease = baseline_energy_decrease*24/1000000 in 8/14 //MW to TWh
replace energy_decrease_ci_high = energy_decrease_ci_high*24/1000000 in 8/14 //MW to TWh
replace energy_decrease_ci_low = energy_decrease_ci_low*24/1000000 in 8/14 //MW to TWh
gen percentage_energy_decrease = energy_decrease/baseline_energy_decrease*100 //Percentage
gen perc_energy_decrease_ci_high = energy_decrease_ci_high/baseline_energy_decrease*100 //Percentage
gen perc_energy_decrease_ci_low = energy_decrease_ci_low/baseline_energy_decrease*100 //Percentage

gen units = "MMBD" in 1/2
replace units = "Mt/D" in 3
replace units = "Bcf/D" in 4/7
replace units = "TWh/D" in 8/14

//Carbon decrease [Mton per day]
gen carbon_decrease = energy_decrease*0.369 in 1 // Ton of carbon per barrel of gasoline 
replace carbon_decrease = energy_decrease*0.402 in 2 // Ton of carbon per barrel of kerosine
replace carbon_decrease = energy_decrease*2.700177676 in 3 // Ton of carbon per ton of subbituminous coal 
replace carbon_decrease = energy_decrease*53.12/1000 in 4/7 // Ton of carbon per thousand cubic feet of gas
replace carbon_decrease = energy_decrease*0.480 in 9 // Ton of carbon per MWh of gas
replace carbon_decrease = energy_decrease*1.09 in 10 // Ton of carbon per MWh of coal
replace carbon_decrease = carbon_decrease[9] + carbon_decrease[10] in  8
replace carbon_decrease = round(carbon_decrease,0.01)

gen carbon_decrease_ci_high = energy_decrease_ci_high*0.369 in 1 // Ton of carbon per barrel of gasoline 
replace carbon_decrease_ci_high = energy_decrease_ci_high*0.402 in 2 // Ton of carbon per barrel of kerosine
replace carbon_decrease_ci_high = energy_decrease_ci_high*2.700177676 in 3 // Ton of carbon per ton of subbituminous coal 
replace carbon_decrease_ci_high = energy_decrease_ci_high*53.12/1000 in 4/7 // Ton of carbon per thousand cubic feet of gas
replace carbon_decrease_ci_high = energy_decrease_ci_high*0.480 in 9 // Ton of carbon per MWh of gas
replace carbon_decrease_ci_high = energy_decrease_ci_high*1.09 in 10 // Ton of carbon per MWh of coal
replace carbon_decrease_ci_high = carbon_decrease_ci_high[9] + carbon_decrease_ci_high[10] in  8

gen carbon_decrease_ci_low = energy_decrease_ci_low*0.369 in 1 // Ton of carbon per barrel of gasoline 
replace carbon_decrease_ci_low = energy_decrease_ci_low*0.402 in 2 // Ton of carbon per barrel of kerosine
replace carbon_decrease_ci_low = energy_decrease_ci_low*2.700177676 in 3 // Ton of carbon per ton of subbituminous coal 
replace carbon_decrease_ci_low = energy_decrease_ci_low*53.12/1000 in 4/7 // Ton of carbon per thousand cubic feet of gas
replace carbon_decrease_ci_low = energy_decrease_ci_low*0.480 in 9 // Ton of carbon per MWh of gas
replace carbon_decrease_ci_low = energy_decrease_ci_low*1.09 in 10 // Ton of carbon per MWh of coal
replace carbon_decrease_ci_low = carbon_decrease_ci_low[9] + carbon_decrease_ci_low[10] in  8

gen carbon_content_baseline = baseline_energy_decrease*0.369 in 1 // Ton of carbon per barrel of gasoline 
replace carbon_content_baseline = baseline_energy_decrease*0.402 in 2 // Ton of carbon per barrel of kerosine
replace carbon_content_baseline = baseline_energy_decrease*2.700177676 in 3 // Ton of carbon per ton of subbituminous coal 
replace carbon_content_baseline = baseline_energy_decrease*53.12/1000 in 4/7 // Ton of carbon per thousand cubic feet of gas
replace carbon_content_baseline = baseline_energy_decrease*0.480 in 9 // Ton of carbon per MWh of gas
replace carbon_content_baseline = baseline_energy_decrease*1.09 in 10 // Ton of carbon per MWh of coal
replace carbon_content_baseline = baseline_energy_decrease[9] + carbon_content_baseline[10] in  8

//NOx decrease [kton per day]
gen nox_decrease = energy_decrease*1.145 in 1 // kg per barrel of gasoline 
replace nox_decrease = energy_decrease*1.145 in 2 // kg per barrel of kerosine
replace nox_decrease = energy_decrease*0.023 in 4/7 // kg per thousand cubic feet of gas
replace nox_decrease = energy_decrease*0.118 in 9 // kg per MWh of gas
replace nox_decrease = energy_decrease*0.724 in 10 // kg per MWh of coal
replace nox_decrease = nox_decrease[9] + nox_decrease[10] in  8

gen nox_decrease_ci_low = energy_decrease_ci_low*1.145 in 1 // kg per barrel of gasoline 
replace nox_decrease_ci_low = energy_decrease_ci_low*1.145 in 2 // kg per barrel of kerosine
replace nox_decrease_ci_low = energy_decrease_ci_low*0.023 in 4/7 // kg per thousand cubic feet of gas
replace nox_decrease_ci_low = energy_decrease_ci_low*0.118 in 9 // kg per MWh of gas
replace nox_decrease_ci_low = energy_decrease_ci_low*0.724 in 10 // kg per MWh of coal
replace nox_decrease_ci_low = nox_decrease_ci_low[9] + nox_decrease_ci_low[10] in  8

gen nox_decrease_ci_high = energy_decrease_ci_high*1.145 in 1 // kg per barrel of gasoline 
replace nox_decrease_ci_high = energy_decrease_ci_high*1.145 in 2 // kg per barrel of kerosine
replace nox_decrease_ci_high = energy_decrease_ci_high*0.023 in 4/7 // kg per thousand cubic feet of gas
replace nox_decrease_ci_high = energy_decrease_ci_high*0.118 in 9 // kg per MWh of gas
replace nox_decrease_ci_high = energy_decrease_ci_high*0.724 in 10 // kg per MWh of coal
replace nox_decrease_ci_high = nox_decrease_ci_high[9] + nox_decrease_ci_high[10] in  8

//SO2 decrease [kton per day]
gen so2_decrease = energy_decrease*0.018 in 1 // kg per barrel of gasoline 
replace so2_decrease = energy_decrease*0.018 in 2 // kg per barrel of kerosine
replace so2_decrease = energy_decrease*0.00027 in 4/7 // kg per thousand cubic feet of gas
replace so2_decrease = energy_decrease*0.012 in 9 // kg per MWh of gas
replace so2_decrease = energy_decrease*0.983 in 10 // kg per MWh of coal
replace so2_decrease = so2_decrease[9] + so2_decrease[10] in  8

gen so2_decrease_ci_low = energy_decrease_ci_low*0.018 in 1 // kg per barrel of gasoline 
replace so2_decrease_ci_low = energy_decrease_ci_low*0.018 in 2 // kg per barrel of kerosine
replace so2_decrease_ci_low = energy_decrease_ci_low*0.00027 in 4/7 // kg per thousand cubic feet of gas
replace so2_decrease_ci_low = energy_decrease_ci_low*0.012 in 9 // kg per MWh of gas
replace so2_decrease_ci_low = energy_decrease_ci_low*0.983 in 10 // kg per MWh of coal
replace so2_decrease_ci_low = so2_decrease_ci_low[9] + so2_decrease_ci_low[10] in  8

gen so2_decrease_ci_high = energy_decrease_ci_high*0.018 in 1 // kg per barrel of gasoline 
replace so2_decrease_ci_high = energy_decrease_ci_high*0.018 in 2 // kg per barrel of kerosine
replace so2_decrease_ci_high = energy_decrease_ci_high*0.00027 in 4/7 // kg per thousand cubic feet of gas
replace so2_decrease_ci_high = energy_decrease_ci_high*0.012 in 9 // kg per MWh of gas
replace so2_decrease_ci_high = energy_decrease_ci_high*0.983 in 10 // kg per MWh of coal
replace so2_decrease_ci_high = so2_decrease_ci_high[9] + so2_decrease_ci_high[10] in  8

//PM decrease [kton per day]
gen pm25_decrease = energy_decrease*0.083 in 1 // kg per barrel of gasoline 
replace pm25_decrease = energy_decrease*0.083 in 2 // kg per barrel of kerosine
replace pm25_decrease = energy_decrease*0.0035 in 4/7 // kg per thousand cubic feet of gas
replace pm25_decrease = energy_decrease*0.026 in 9 // kg per MWh of gas
replace pm25_decrease = energy_decrease*0.115 in 10 // kg per MWh of coal
replace pm25_decrease = pm25_decrease[9] + pm25_decrease[10] in  8

gen pm25_decrease_ci_low = energy_decrease_ci_low*0.083 in 1 // kg per barrel of gasoline 
replace pm25_decrease_ci_low = energy_decrease_ci_low*0.083 in 2 // kg per barrel of kerosine
replace pm25_decrease_ci_low = energy_decrease_ci_low*0.0035 in 4/7 // kg per thousand cubic feet of gas
replace pm25_decrease_ci_low = energy_decrease_ci_low*0.026 in 9 // kg per MWh of gas
replace pm25_decrease_ci_low = energy_decrease_ci_low*0.115 in 10 // kg per MWh of coal
replace pm25_decrease_ci_low = pm25_decrease_ci_low[9] + pm25_decrease_ci_low[10] in  8

gen pm25_decrease_ci_high = energy_decrease_ci_high*0.083 in 1 // kg per barrel of gasoline 
replace pm25_decrease_ci_high = energy_decrease_ci_high*0.083 in 2 // kg per barrel of kerosine
replace pm25_decrease_ci_high = energy_decrease_ci_high*0.0035 in 4/7 // kg per thousand cubic feet of gas
replace pm25_decrease_ci_high = energy_decrease_ci_high*0.026 in 9 // kg per MWh of gas
replace pm25_decrease_ci_high = energy_decrease_ci_high*0.115 in 10 // kg per MWh of coal
replace pm25_decrease_ci_high = pm25_decrease_ci_high[9] + pm25_decrease_ci_high[10] in  8

//VOC decrease [kton per day]
gen voc_decrease = energy_decrease*0.621 in 1 // kg per barrel of gasoline 
replace voc_decrease = energy_decrease*0.621 in 2 // kg per barrel of kerosine
replace voc_decrease = energy_decrease*0.0025 in 4/7 // kg per thousand cubic feet of gas
replace voc_decrease = energy_decrease*0.019 in 9 // kg per MWh of gas
replace voc_decrease = energy_decrease*0.008 in 10 // kg per MWh of coal
replace voc_decrease = voc_decrease[9] + voc_decrease[10] in  8

gen voc_decrease_ci_low = energy_decrease_ci_low*0.621 in 1 // kg per barrel of gasoline 
replace voc_decrease_ci_low = energy_decrease_ci_low*0.621 in 2 // kg per barrel of kerosine
replace voc_decrease_ci_low = energy_decrease_ci_low*0.0025 in 4/7 // kg per thousand cubic feet of gas
replace voc_decrease_ci_low = energy_decrease_ci_low*0.019 in 9 // kg per MWh of gas
replace voc_decrease_ci_low = energy_decrease_ci_low*0.008 in 10 // kg per MWh of coal
replace voc_decrease_ci_low = voc_decrease_ci_low[9] + voc_decrease_ci_low[10] in  8

gen voc_decrease_ci_high = energy_decrease_ci_high*0.621 in 1 // kg per barrel of gasoline 
replace voc_decrease_ci_high = energy_decrease_ci_high*0.621 in 2 // kg per barrel of kerosine
replace voc_decrease_ci_high = energy_decrease_ci_high*0.0025 in 4/7 // kg per thousand cubic feet of gas
replace voc_decrease_ci_high = energy_decrease_ci_high*0.019 in 9 // kg per MWh of gas
replace voc_decrease_ci_high = energy_decrease_ci_high*0.008 in 10 // kg per MWh of coal
replace voc_decrease_ci_high = voc_decrease_ci_high[9] + voc_decrease_ci_high[10] in  8

gen nox_decrease_deaths = nox_decrease*0.2912 // per day
gen so2_decrease_deaths = so2_decrease*2.7486
gen pm25_decrease_deaths = pm25_decrease*7.9521
gen voc_decrease_deaths = voc_decrease*0.6924

gen nox_decrease_deaths_ci_low = nox_decrease_ci_low*0.2912 // per day
gen so2_decrease_deaths_ci_low = so2_decrease_ci_low*2.7486
gen pm25_decrease_deaths_ci_low = pm25_decrease_ci_low*7.9521
gen voc_decrease_deaths_ci_low = voc_decrease_ci_low*0.6924

gen nox_decrease_deaths_ci_high = nox_decrease_ci_high*0.2912 // per day
gen so2_decrease_deaths_ci_high = so2_decrease_ci_high*2.7486
gen pm25_decrease_deaths_ci_high = pm25_decrease_ci_high*7.9521
gen voc_decrease_deaths_ci_high = voc_decrease_ci_high*0.6924

gen decrease_deaths = (nox_decrease_deaths + so2_decrease_deaths + pm25_decrease_deaths + voc_decrease_deaths)*30.5 // deaths per month
gen decrease_deaths_ci_low = (nox_decrease_deaths_ci_low + so2_decrease_deaths_ci_low + pm25_decrease_deaths_ci_low + voc_decrease_deaths_ci_low)*30.5 // deaths per month
gen decrease_deaths_ci_high = (nox_decrease_deaths_ci_high + so2_decrease_deaths_ci_high + pm25_decrease_deaths_ci_high + voc_decrease_deaths_ci_high)*30.5 // deaths per month

gen index = _n

************************************************************************
//SUMMARY FIGURES
drop if index > 10
drop if index == 3
drop if index == 5
drop if index == 7
gen order=6 if label=="Motor gasoline"
replace order=7 if label=="Jet fuel"
replace order=5 if label=="Natural gas res.+com."
replace order=4 if label=="Natural gas industrial"
replace order=3 if label=="Gas-fired electricity"
replace order=2 if label=="Coal-fired electricity"
replace order=1 if label=="Electricity demand"
graph hbar percentage_energy_decrease, over(label, sort(order)) ytitle(Percent declines in consumption) graphregion(color(white)) plotregion(color(white)) lintensity(*0.5) intensity(*0.5) ///
note("Note: Reduction relative to consumption in the same period in 2019") blabel(bar, position(outside)) yscale(r(0 57))
replace energy_decrease = round(energy_decrease,0.01)
generate zero = 37 in 1
replace zero = 63 in 2
replace zero = 40 in 3
replace zero = 16 in 4
replace zero = 23 in 6
replace zero = 8 in 7
replace zero = 10 in 5
gen energy_decrease_string = string(energy_decrease)
twoway (bar percentage_energy_decrease order, horizontal) (rcap perc_energy_decrease_ci_high perc_energy_decrease_ci_low order, horizontal) (sc order zero , mlabel(energy_decrease_string) mlabcolor(black) msymbol(i)) ///
, note("Note: Reduction relative to consumption in the same period in 2019")  xscale(r(0 72)) graphregion(color(white)) plotregion(color(white)) ///
ylabel(7 "Jet fuel" 6 "Motor gasoline" 5 "Natural gas res.+com." 4 "Natural gas industrial" 3 "Gas-fired electricity" 2 "Coal-fired electricity" 1 "Electricity demand", angle(horizontal) nogrid) legend(off) ///
xtitle(Percent declines in consumption) ytitle("")
graph export Summary_figure_energy_old.eps, replace
graph export Summary_figure_energy_old.emf, replace

gen energy_decrease_tj = energy_decrease*5861.5 in 1/2 // MMBD -> TJ/day
gen energy_decrease_ci_high_tj = energy_decrease_ci_high*5861.5 in 1/2 // MMBD -> TJ/day
gen energy_decrease_ci_low_tj = energy_decrease_ci_low*5861.5 in 1/2 // MMBD -> TJ/day
replace energy_decrease_tj = energy_decrease*1088.6 in 3/4 // Bcf -> TJ/day
replace energy_decrease_ci_high_tj = energy_decrease_ci_high*1088.6 in 3/4 // Bcf -> TJ/day
replace energy_decrease_ci_low_tj = energy_decrease_ci_low*1088.6 in 3/4 // Bcf -> TJ/day
replace energy_decrease_tj = energy_decrease*3600 in 5/7 // TWh -> TJ/day
replace energy_decrease_ci_high_tj = energy_decrease_ci_high*3600 in 5/7 // TWh -> TJ/day
replace energy_decrease_ci_low_tj = energy_decrease_ci_low*3600 in 5/7 // TWh -> TJ/day

clonevar x = order
replace x = x - 0.45
twoway (bar percentage_energy_decrease x, horizontal barwidth(0.45) xaxis(1)) (bar energy_decrease_tj order, horizontal barwidth(0.45) xaxis(2))  ///
(rcap perc_energy_decrease_ci_high perc_energy_decrease_ci_low x, horizontal lcolor(black) xaxis(1)) (rcap energy_decrease_ci_high_tj energy_decrease_ci_low_tj order, horizontal lcolor(black) xaxis(2)) ///
, note("Note: Reduction relative to consumption in the same period in 2019")  graphregion(color(white)) plotregion(color(white)) ///
ylabel(6.8 "Jet fuel" 5.8 "Motor gasoline" 4.8 "Natural gas res.+com." 3.8 "Natural gas industrial" 2.8 "Gas-fired electricity" 1.8 "Coal-fired electricity" 0.8 "Electricity demand", angle(horizontal) nogrid) ///
xtitle(Percent declines in consumption, axis(1)) xtitle(Absolute declines in consumption (TJ/day), axis(2)) ytitle("") legend( order(3 "Absolute decline" 1 " Percentage decline" ) region(lcolor(white))) xscale(r(0 65))
graph export Summary_figure_energy.eps, replace
graph export Summary_figure_energy.emf, replace 

drop if order==1
format carbon_decrease %03.2f
replace zero = 1.36 in 1
replace zero = 66 in 2
replace zero = 29 in 3
replace zero = 12 in 4
replace zero = 22 in 5
replace zero = 5 in 6
twoway (bar carbon_decrease order, horizontal) (rcap carbon_decrease_ci_high carbon_decrease_ci_low order, horizontal) (sc order carbon_decrease_ci_low , mlabel(carbon_decrease) mlabcolor(black) msymbol(i)) ///
, xscale(r(0 1.2)) graphregion(color(white)) plotregion(color(white)) ///
ylabel(7 "Jet fuel" 6 "Motor gasoline" 5 "Natural gas res.+com." 4 "Natural gas industrial" 3 "Gas-fired electricity" 2 "Coal-fired electricity", angle(horizontal) nogrid) legend(off) ///
xtitle(Decline in carbon emissions [MtCO2/day]) ytitle("")
graph export Summary_figure_carbon_old.eps, replace
graph export Summary_figure_carbon_old.emf, replace

clonevar y = order
replace y = y - 0.45
twoway (bar percentage_energy_decrease y, horizontal barwidth(0.45) xaxis(1)) (bar carbon_decrease order, horizontal barwidth(0.45) xaxis(2))  ///
(rcap perc_energy_decrease_ci_high perc_energy_decrease_ci_low y, horizontal lcolor(black) xaxis(1)) (rcap carbon_decrease_ci_high carbon_decrease_ci_low order, horizontal lcolor(black) xaxis(2)) ///
, note("Note: Reduction relative to consumption in the same period in 2019")  graphregion(color(white)) plotregion(color(white)) ///
ylabel(6.8 "Jet fuel" 5.8 "Motor gasoline" 4.8 "Natural gas res.+com." 3.8 "Natural gas industrial" 2.8 "Gas-fired electricity" 1.8 "Coal-fired electricity", angle(horizontal) nogrid) ///
xtitle(Percent declines in carbon emissions, axis(1)) xtitle(Absolute declines in carbon emissions (MtCO2/day), axis(2)) ytitle("") legend( order(3 "Absolute decline" 1 " Percentage decline" ) region(lcolor(white))) xscale(r(0 65))
graph export Summary_figure_carbon.eps, replace 
graph export Summary_figure_carbon.emf, replace

format decrease_deaths %3.0f
twoway (bar decrease_deaths order, horizontal) (rcap decrease_deaths_ci_high decrease_deaths_ci_low order, horizontal) (sc order decrease_deaths_ci_low , mlabel(decrease_deaths) mlabcolor(black) msymbol(i)) ///
, graphregion(color(white)) plotregion(color(white)) ///
ylabel(7 "Jet fuel" 6 "Motor gasoline" 5 "Natural gas res.+com." 4 "Natural gas industrial" 3 "Gas-fired electricity" 2 "Coal-fired electricity", angle(horizontal) nogrid) legend(off) xscale(r(0 200)) ///
xtitle(Decline in emissions-related deaths per month) ytitle("")
graph export Summary_figure_deaths.eps, replace
graph export Summary_figure_deaths.png, replace

gen nox_decrease_relative=nox_decrease/(10327/365)*100
gen so2_decrease_relative=so2_decrease/(2735/365)*100
gen pm25_decrease_relative=pm25_decrease/(18123/365)*100
gen voc_decrease_relative=voc_decrease/(15975/365)*100

gen nox_decrease_relative_ci_low=nox_decrease_ci_low/(10327/365)*100
gen so2_decrease_relative_ci_low=so2_decrease_ci_low/(2735/365)*100
gen pm25_decrease_relative_ci_low=pm25_decrease_ci_low/(18123/365)*100
gen voc_decrease_relative_ci_low=voc_decrease_ci_low/(15975/365)*100

gen nox_decrease_relative_ci_high=nox_decrease_ci_high/(10327/365)*100
gen so2_decrease_relative_ci_high=so2_decrease_ci_high/(2735/365)*100
gen pm25_decrease_relative_ci_high=pm25_decrease_ci_high/(18123/365)*100
gen voc_decrease_relative_ci_high=voc_decrease_ci_high/(15975/365)*100

gen decrease_relative = nox_decrease_relative[1] in 4
replace decrease_relative = so2_decrease_relative[1] in 3
replace decrease_relative = pm25_decrease_relative[1] in 2
replace decrease_relative = voc_decrease_relative[1] in 1

gen decrease_relative_ci_high = nox_decrease_relative_ci_high[1] in 4
replace decrease_relative_ci_high = so2_decrease_relative_ci_high[1] in 3
replace decrease_relative_ci_high = pm25_decrease_relative_ci_high[1] in 2
replace decrease_relative_ci_high = voc_decrease_relative_ci_high[1] in 1

gen decrease_relative_ci_low = nox_decrease_relative_ci_low[1] in 4
replace decrease_relative_ci_low = so2_decrease_relative_ci_low[1] in 3
replace decrease_relative_ci_low = pm25_decrease_relative_ci_low[1] in 2
replace decrease_relative_ci_low = voc_decrease_relative_ci_low[1] in 1
gen order2 = 1 in 1 
replace order2 = 2 in 2
replace order2 = 3 in 3 
replace order2 = 4 in 4 
gen decrease_relative_string = string(decrease_relative)
twoway (bar decrease_relative order2, horizontal) (rcap decrease_relative_ci_high decrease_relative_ci_low order2, horizontal) (sc order2 decrease_relative_ci_low , mlabel(decrease_relative_string) mlabcolor(black) msymbol(i)) ///
, note("Note: Reduction relative to consumption in the same period in 2019")  graphregion(color(white)) plotregion(color(white)) ///
ylabel(1 "SO2" 2 "PM10" 3 "VOC" 4 "NOx", angle(horizontal) nogrid) legend(off) ///
xtitle(Percent declines in consumption) ytitle("") xscale(r(0 18))
graph export Summary_figure_local_emissions.eps, replace
graph export Summary_figure_local_emissions.png, replace
