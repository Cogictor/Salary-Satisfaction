// Set up
clear all
set more off

cd "/cal/exterieurs/dferreira-22/Downloads/data/"

// Log
capture log close
log using "project_log.log", replace

// Load data
use "glassdoor_.dta", clear
describe


// Clean inapplicable value
tab compRevenue
drop if (compRevenue=="Unknown / Non-Applicable")
tab compSize
drop if (compSize=="Unknown")
tab compAge
drop if(compAge==2023)

gen sal = salary/1000
gen log_salary = log(salary)
label variable sal "salary(thousands)"

// Visualization
// Summary
asdoc summarize salary starRating ceoRating recommendRating benefitRating compAge

// Scatter plot matrix
graph matrix starRating sal ceoRating recommendRating compAge benefitRating, half
graph export "matrix.png"

// Histogram
histogram sal, xtitle("salary(thousands)") name(h1)
histogram compAge, xtitle("company age") name(h2)
graph combine h1 h2, ysize(2)
graph export "hists.png"

// Bar plot - Analysis company sector
graph hbar starRating , over(compSector) yline(3.722584) name(bar1, replace)
graph hbar salary , over(compSector) yline( 47873.81) name(bar2, replace)
graph combine bar1 bar2, xsize(10)
graph export "bars.png"

// Correlation table
estpost correlate starRating sal ceoRating recommendRating compAge benefitRating, matrix
esttab using "corr.csv", replace unstack not noobs nonote compress label


// Encode categorical variable
encode compSector, gen(compSec_en)
encode compRevenue, gen(compRevenue_en)
encode compSize, gen(compSize_en)
encode country, gen(country_en)


// Running regression with linear assumption
eststo clear
eststo: reg starRating sal, robust
estadd local benefit "No", replace
estadd local environment "No", replace
estadd local comp_sec "No", replace
estadd local comp_size "No", replace
estadd local country "No", replace

eststo: reg starRating sal benefitRating, robust
estadd local benefit "Yes", replace
estadd local environment "No", replace
estadd local comp_sec "No", replace
estadd local comp_size "No", replace
estadd local country "No", replace

eststo: reg starRating sal benefitRating ceoRating, robust
estadd local benefit "Yes", replace
estadd local environment "Yes", replace
estadd local comp_sec "No", replace
estadd local comp_size "No", replace
estadd local country "No", replace


eststo: reg starRating sal i.compSec_en, robust
estadd local benefit "No", replace
estadd local environment "No", replace
estadd local comp_sec "Yes", replace
estadd local comp_size "No", replace
estadd local country "No", replace

eststo: reg starRating sal i.compSec_en compAge i.compRevenue_en i.compSize_en, r
estadd local benefit "No", replace
estadd local environment "No", replace
estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "No", replace

eststo: reg starRating sal i.compSec_en i.country_en, r
estadd local benefit "No", replace
estadd local environment "No", replace
estadd local comp_sec "Yes", replace
estadd local comp_size "No", replace
estadd local country "Yes", replace


eststo: reg starRating sal ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, robust
estadd local benefit "Yes", replace
estadd local environment "Yes", replace
estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "Yes", replace

esttab using linear.doc,  keep (_cons sal ceoRating compAge benefitRating) stats(r2 benefit environment comp_sec comp_size country, labels ("adj R-sq" "benefit" "environment" "company sector" "company influence" "country")) varwidth(20)

testparm i.compRevenue_en
testparm i.compSize_en

// Run non-linear model: Logarithmic
gen log_star = log(starRating)

reg log_star log_salary ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, robust


// Run non-linear model: Polynomial
eststo clear
gen sal2 = sal*sal
gen sal3 = sal2*sal
eststo: reg starRating sal ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r

eststo: reg starRating sal sal2 sal3 ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r

//Add interaction of sal with other control variables
gen sal_ceo = sal*ceoRating
gen sal_age = sal*compAge
gen sal_ben = sal*benefitRating


gen sal2_ceo = sal2*ceoRating
gen sal3_ceo = sal3*ceoRating
gen sal2_age = sal2*compAge
gen sal3_age = sal3*compAge
gen sal2_ben = sal2*benefitRating
gen sal3_ben = sal3*benefitRating


eststo clear
eststo: reg starRating sal ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r

estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "Yes", replace
eststo: reg starRating sal sal2 sal3 ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r

estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "Yes", replace
eststo: reg starRating sal sal2 sal3 sal_age ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r

estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "Yes", replace
eststo: reg starRating sal sal2 sal3 sal_ben sal2_ben ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r

estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "Yes", replace

eststo: reg starRating sal sal2 sal3 sal_ben sal2_ben sal3_ben ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r

estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "Yes", replace
eststo: reg starRating sal sal2 sal3 sal_ceo sal2_ceo sal3_ceo ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r

estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "Yes", replace
eststo: reg starRating sal sal2 sal3 sal_age sal_ceo sal_ben ceoRating compAge benefitRating i.country_en i.compSec_en i.compRevenue_en i.compSize_en, r
estadd local comp_sec "Yes", replace
estadd local comp_size "Yes", replace
estadd local country "Yes", replace

esttab, keep(sal sal2 sal3 sal_ceo sal_age sal_ben sal2_ceo sal2_ben sal3_ceo sal3_ben ceoRating compAge benefitRating) stats(comp_sec comp_size country N r2, labels ("company sector" "company influence" "country" "N" "adj R-sq")) varwidth(17)

log close

