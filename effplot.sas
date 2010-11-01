 /*--------------------------------------------------------------*
  *    Name: effplot.sas                                         *
  *   Title: Effect displays for linear models                   *
        Doc: http://www.datavis.ca/sasmac/effplot.html     
  *--------------------------------------------------------------*
  *  Author:  Michael Friendly            <friendly@yorku.ca>    *
  * Created: 15 Mar 2008 11:46:14                                *
  * Revised: 31 Mar 2009 12:10:23                                *
  * Version: 0.7-2                                               *
  *                                                              *
  *--------------------------------------------------------------*/
 /*=
=Description:
 
 The EFFPLOT macro produces an 'effect display,'  a plot of predicted
 values for one term in a linear or generalized linear mode.  In this
 plot, all lower-order terms marginal to a given effect are absorbed,
 and other terms in the model are averaged over. These plots are particularly
 useful for visualizing interactions in complex models.
 
 At present, these plots are provided for PROC REG, PROC GLM, PROC
 LOGISTIC and PROC GENMOD.

==Method:

 The essential idea is to calculate predicted values from the model over
 a grid of values of all predictors and then plot the average of these
 over variables not included in the given term.  To do this, the set of
 predictor values specified by the GRID= parameter is appended to the
 input data set. Predicted values (and appropriate standard errors) are 
 then generated by the fitting procedure. This is similar to the use of
 the SCORE statement in PROC LOGISTIC, but with more functionality.

 In this version, using the MEANPLOT macro to do the plotting,  the 
 parameters XVAR=, CVAR= and PVAR= determine the  variables displayed 
 in a 1-way to 3-way effect.  All other predictors are effectively
 averaged over.
 
 As well, the macro calculates appropriate point-wise standard errors 
 and upper/lower 1-ALPHA intervals for  each grid point.  These are
 returned in the OUT= data set, but this version does not plot them. 

=Usage:

 The EFFPLOT macro is defined with keyword parameters.
 The arguments may be listed within parentheses in any order, separated
 by commas. For example: 
 
	%effplot(data=myexp, y=Response, model=X1 X2,
	   grid=%str(X1=0 to 10, X2=5 10 15),
	   xvar=X1, cvar=X2);
 
==Parameters:

* DATA=       The name of the input data set

* Y=          Name of response variable in the input dataset

* RESPONSE=   Synonym for Y=

* CLASS=      Class (factor) variables

* MODEL=      Right-hand side of MODEL statement

* XVAR=       Horizontal value for plot [NUMERIC|CHAR]

* CVAR=       Variable for curves within each plot, for a 2-way or 3-way effect

* PVAR=       Variable defining the panels of multiple plots, for a 3-way effect

* PROC=       Procedure to run: GLM, REG, LOGISTIC or GENMOD [Default: PROC=REG]

* PROCOPTS=   Extra options on PROC statement

* MODOPTS=    Extra options on the MODEL statement

* GRID=       Grid of predictor values for plot or grid data set.  This should
              be a specification in the form of a comma-separated list of
			  VAR=VALUes, as accepted by the EXPGRID macro.  
			  
			  All predictors in the model must be assigned a value so that
			  a predicted value can be calculated for all observations in the
			  grid data set.
			   
			  For a numeric variable that is to be averaged over in the plot, 
			  you can specify a single number, representing the value at which 
			  other effects are averaged. For example, with sex (0/1) as a
			  predictor with 67% males (1), include 'sex=0.67' to represent
			  sex at the average level in the sample, or 'sex=0.5' for
			  the average level in an equal population of males and females.

* ALPHA=      Alpha for lower/upper limits [Default: ALPHA=0.33]

* YLAB=       Label for fitted response variable [Default: YLAB=&Y]

* HAXIS=      Axis statement for horizontal axis

* VAXIS=      Axis statement for response axis

* LEGEND=     Legend statement for custom CVAR legend

* SYMBOLS=    List of SAS/GRAPH symbols for the levels of the CVAR=variable.  
		      There should be as many symbols as there are distinct values of 
		      the CVAR=variable. 
			  [Default: SYMBOLS=%STR(CIRCLE SQUARE $ : TRIANGLE = X _ Y)]

* COLORS=     List of SAS/GRAPH colors for the levels of the CVAR=variable.
              There should be as many colors as there are distinct values 
			  of the CVAR=variable. 
			  [Default: COLORS=BLACK RED BLUE GREEN BROWN ORANGE PURPLE YELLOW]

* LINES=      List of SAS/GRAPH line styles for the levels of the CVAR=variable.
              There should be as many lines as there are distinct values of 
			  the CVAR=variable. 
			  [Default: LINES=1 20 41 21 7 14 33 12]

* ANNO=       Additional input annotate data set

* PRINT=      Print the OUT= data set?

* OUT=        The name of the output data set [Default: OUT=EFFECTS]

* GOUT=       The name of the graphics catalog [Default: GOUT=WORK.GSEG]

* NAME=       The name of the graph in the graphic catalog [Default: NAME=EFFPLOT]
                
=Examples:

   *-- arrests1.sas; 
   %include data(arrests);
   axis1 order=(0.5 to 0.8 by 0.1) label=(a=90);
   title 'Toronto Star arrests data: Colour * Age effect';
   %effplot(data=arrests,
	   y=released,
	   class=colour employed citizen,
	   model=employed citizen checks colour|year colour|age,
	   grid=%str(employed=0 1, citizen=0 1, checks=0 to 6, colour=Black White, age=15 to 45 by 5, year=1997 to 2002),
	   cvar=colour,
	   xvar=age,
	   vaxis=axis1,
	   ylab=Prob(Released),
	   proc=logistic, procopts=descending);


 =*/

%macro effplot(
	data=,
	y=,           /* name of response variable in the input dataset     */
	response=,    /* synonym for Y=                                     */
	class=,       /* class (factor) variables                           */
	model=,       /* right-hand side of MODEL statement                 */
	xvar=,        /* horizontal value for plot [NUMERIC|CHAR]           */
	cvar=,        /* variable for curves within each plot               */
	pvar=,        /* variable defining the panels of multiple plots     */
	proc=reg,     /* procedure to run: GLM, REG, LOGISTIC or GENMOD     */
	procopts=,    /* extra options on PROC statement                    */
	modopts=,     /* extra options on MODEL statement                   */
	grid=,        /* grid of predictor values for plot or grid data set */
	alpha=0.33,   /* alpha for lower/upper limits                       */
	ylab=&y,      /* label for fitted response variable                 */
	haxis=,       /* axis statement for horizontal axis                 */
	vaxis=,       /* axis statement for response axis                   */
	legend=,      /* legend statement for custom CVAR legend            */
	symbols=%str(circle square $ : triangle = X _ Y),
	colors=BLACK RED BLUE GREEN BROWN ORANGE PURPLE YELLOW,
	lines=1 20 41 21 7 14 33 12,
	anno=,        /* additional input annotate data set                 */
	print=N,      /* print the OUT= data set?                           */
	out=effects,  /* name of output data set (_pred_ and SEpred)        */
	gout=,        /* name of graphic catalog                            */
  	name=effplot  /* name of graphic catalog entry                      */
	);
	
%local abort me;
%let abort=0;
%let me=&sysmacroname;
%let print=%substr(%upcase(&print),1,1);

%if (%length(&y) = 0) %then %do;
	%if %length(&response)>0 %then %let y=&response;
	%end;

%if %length(&y)=0 | %length(&model)=0
	%then %do;
		%put ERROR: The Y= and MODEL= parameters must be specified;
      %let abort=1;
		%goto DONE;
	%end;

options nonotes;

*-- Either create the grid data set or modify the passed one;
%if %length(%scan(&grid, 2))>0 %then %do;
	%expgrid(&grid, _in_=1);
	%end;
%else %do;
	data _grid_;
		set &grid;
		_in_=1;
	%end;


*-- Join the grid to the input data set;
data _all_;
	set &data _grid_;
run;

%let proc=%upcase(&proc);

%if &proc=REG %then %do;
	%if %length(&class) %then %do;
		%put &me: CLASS= variables not allowed with PROC=REG. Ignored;
		%end;
	%if %index(&model, %str(|*)) %then %do;
		%put ERROR: &me: GLM-style formulas not allowed in PROC REG;
		%end;
	proc reg data=_all_ &procopts;
		model &y = &model / covb alpha=&alpha;
		output out=_predict_ predicted=_pred_ stdp=sepred lclm=lower uclm=upper;
	%if &syserr > 4 %then %let abort=1; %if &abort %then %goto DONE;
	%end;
%else %if &proc=GLM %then %do;
	proc glm data=_all_ &procopts;
	%if %length(&class) %then %do;
		class &class;
		%end;
		model &y = &model / alpha=&alpha;
		output out=_predict_ predicted=_pred_ stdp=sepred lclm=lower uclm=upper;
	%if &syserr > 4 %then %let abort=1; %if &abort %then %goto DONE;
	%end;
%else %if &proc=LOGISTIC %then %do;
	proc logistic data=_all_ alpha=&alpha &procopts;
	%if %length(&class) %then %do;
		class &class;
		%end;
		model &y = &model / covb;
		output out=_predict_ predicted=_pred_  l=lower u=upper
		                     xbeta=logit stdxbeta=selogit;
	%if &syserr > 4 %then %let abort=1; %if &abort %then %goto DONE;
	%end;
%else %if &proc=GENMOD %then %do;
	proc genmod data=_all_ alpha=&alpha &procopts;
	%if %length(&class) %then %do;
		class &class;
		%end;
		model &y = &model / covb alpha=&alpha &modopts;
		output out=_predict_ predicted=_pred_  l=lower u=upper
		                     xbeta=logit stdxbeta=selogit;
	%if &syserr > 4 %then %let abort=1; %if &abort %then %goto DONE;
	%end;
%else %do;
	%put ERROR: &me: The %proc procedure is not recognized;
	%end;

data &out;
	set _predict_(where =(_in_=1));
	%if %length(&ylab) %then %do;
		label _pred_ = "&ylab";
		%end;
%if &print=Y %then %do;
proc print data=&out;
	run;
	%end;

%meanplot(data=&out, response=_pred_,
	class=&xvar &cvar &pvar,
	vaxis=&vaxis,
	haxis=&haxis,
	legend=&legend,
	symbols=&symbols,
	lines=&lines,
	anno=&anno,
	name=&name,
	z=0,            /* dont plot error bars in this version */
	gout=&gout
/*
	xvar=&xvar,
	cvar=&cvar,
	pvar=&pvar
*/
	);

%done:
%if &abort %then %put ERROR: The &me macro ended abnormally.;
options notes;
%mend;
