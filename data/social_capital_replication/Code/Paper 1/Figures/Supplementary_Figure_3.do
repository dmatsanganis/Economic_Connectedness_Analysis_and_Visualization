********************************************************************************
** This do file replicates Supplementary Figure 3: ZIP Code-Level Correlations between Upward Mobility and Measures of Social Capital
********************************************************************************

clear all 

********************************************************************************
**# 0. Setup 
********************************************************************************

* Define geographic unit 
local geo zip

* Merge public data with the FB dataset
import delimited "${fb_data}/social_capital_`geo'.csv", clear 
merge 1:1 `geo' using "${public_data}/`geo'_covariates.dta"

		
* List of social capital measures
* Note: only a subset of measures is available with public data: economic connectedness, clustering, support ratio, civic organizations, and volunteering rate
local vars "ec_`geo' clustering_`geo' support_ratio_`geo' civic_organizations_`geo' volunteering_rate_`geo'"

* List of outcomes 
local outcomes kfr_pooled_pooled_p25
label var kfr_pooled_pooled_p25 "Upward Mobility"

* Define weight: no. of children with parents with below-median household income
local weight = "num_below_p50"

* Set SE clustering level 
local cluster_var = "cz"


tempfile merged_data
save `merged_data'


********************************************************************************
**# 1. Panel A: Univariate Correlations 
********************************************************************************
					  
foreach depvar of local outcomes {
	
	use `merged_data', clear
	postutil clear
	local varlabel `: var label `depvar''
	
	tempname SuppFigure3a
	postfile `SuppFigure3a' str25 variable corr se using "${paper1_figs}/SuppFigure3a.dta", replace
	foreach var of local vars {

		preserve 
		
		keep if !missing(`depvar', `var', `weight', `cluster_var')
		
		* Standardize outcome and social capital measures
		center `depvar' `var' [aweight = `weight'], inplace standardize		
		
		* Univariate correlations
		reg `depvar' `var' [aweight = `weight'], vce(cluster `cluster_var')
		post `SuppFigure3a' ("`var'") (`=_b[`var']') (`=_se[`var']')
		
		restore

	}
	
	
	postclose `SuppFigure3a'
	use "${paper1_figs}/SuppFigure3a.dta", clear
	
	* We will plot the magnitude of the correlation (corr) while using different markers to indicate its sign
	gen og_corr = corr
	replace corr = abs(corr)
	
	* Upper and lower 95% confidence intervals. Note that lower confidence interval is always nonnegative for presentation purposes.
	gen conf_upper =  corr + 1.96 * se
	gen conf_lower =  max(corr - 1.96 * se, 0) 
	
	* Variable to order social capital measures on graph
	gen var_order = - _n
		
	* corrplot
	twoway (rcap conf_upper conf_lower var_order,  color(gs6) horizontal msize(medsmall) lwidth(medthin)) ///
		   (scatter var_order corr if og_corr >= 0, mcolor(green) msymbol(circle) msize(medium))  ///
		   (scatter var_order corr if og_corr < 0, mcolor(red) msymbol(triangle) msize(medium)) ///
			, ylabel(-1 `"Economic Connectedness"' ///
					 -2 `"Clustering"' ///
					 -3 `"Support Ratio"' ///
					 -4 `"Civic Organizations"' ///
					 -5 `"Volunteering Rate"' ///
					  , labsize(small) nogrid) ///	
			  ytitle("") ///
			  xtitle("Magnitude of Pop-Wtd. Univariate Correlation with" "`varlabel' across ZIP Codes", size(small)) ///
			  xlabel(0(0.2)0.8, format(%03.1f) gmax gmin nogrid labsize(small)) ///
			  legend(order(2 "Positive" 3 "Negative") pos(6) ring(1) row(1) size(small)) ///
			  title("{bf:ZIP Code-Level Correlations between Upward Mobility and Measures of Social Capital}" " " "{it:A. Univariate Correlations}" " ", size(small) span)
				  
	graph export "${paper1_figs}/Supplementary_Figure_3a.pdf", replace	
	
	
	* Delete correlations tempfile 
	erase "${paper1_figs}/SuppFigure3a.dta"
}

	
********************************************************************************
**# 2. Panel B: Coefficients from Multivariate Regression 
********************************************************************************

* Note: Since we only use a subset of the variables used in the paper, the multivariate analysis is not directly comparable to that in the paper

						 
foreach depvar of local outcomes {
		
	use `merged_data', clear
		
	postutil clear 
	local varlabel `: var label `depvar''
		
	* standardize outcome and social capital measures with non-null observations
	keep if !missing(`cluster_var')
	quietly reg `depvar' `vars' [aweight = `weight'], vce(cluster `cluster_var')
	keep if e(sample) == 1
	center `depvar' `vars' [aweight = `weight'], inplace standardize
		
	* Now run regression on standardized variables
	reg `depvar' `vars' [aweight = `weight'], vce(cluster `cluster_var') 

	postutil clear
	tempname SuppFigure3b
	postfile `SuppFigure3b' str25 variable corr se using "${paper1_figs}/SuppFigure3b.dta", replace

	foreach var of local vars {
		post `SuppFigure3b' ("`var'") (`=_b[ `var' ]') (`=_se[ `var' ]')
	}

	postclose `SuppFigure3b'
	use "${paper1_figs}/SuppFigure3b.dta", clear

	* We will plot the magnitude of the correlation (corr) while using different markers to indicate its sign
	gen og_corr = corr
	replace corr = abs(corr)
	
	* Upper and lower 95% confidence intervals. Note that lower confidence interval is always nonnegative for presentation purposes.
	gen conf_upper =  corr + 1.96 * se
	gen conf_lower =  max(corr - 1.96 * se, 0) 
	
	* Variable to order social capital measures on graph
	gen var_order = - _n
		
	* corrplot
	twoway (rcap conf_upper conf_lower var_order,  color(gs6) horizontal msize(medsmall) lwidth(medthin)) ///
		   (scatter var_order corr if og_corr >= 0, mcolor(green) msymbol(circle) msize(medium))  ///
		   (scatter var_order corr if og_corr < 0, mcolor(red) msymbol(triangle) msize(medium)) ///
			, ylabel(-1 `"Economic Connectedness"' ///
					 -2 `"Clustering"' ///
					 -3 `"Support Ratio"' ///
					 -4 `"Civic Organizations"' ///
					 -5 `"Volunteering Rate"' ///
				      , labsize(small) nogrid) ///	
			  ytitle("") ///
			  xtitle("Multivariable Regression Coefficient" "on Standardized Measure", size(small)) ///
			  xlabel(0(0.2)1.0, format(%03.1f) gmax gmin nogrid labsize(small)) ///
			  legend(order(2 "Positive" 3 "Negative") pos(6) ring(1) row(1) size(small)) ///
			  title("{bf:ZIP Code-Level Correlations between Upward Mobility and Measures of Social Capital}" " " "{it:B. Coefficients from Multivariable Regression}" " ", size(small) span)
	
	graph export "${paper1_figs}/Supplementary_Figure_3b.pdf", replace
	
	
	* Delete correlations tempfile 
	erase "${paper1_figs}/SuppFigure3b.dta"
}

