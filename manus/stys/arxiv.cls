%% manus/stys/arxiv.cls — STAGE's default document class: a compact,
%% arXiv-style preprint look.
%%
%% This file owns the LOOK: page geometry, fonts, the title panel, headings,
%% captions, floats, and bibliography style. It is the layer a venue swap
%% replaces — drop the venue's class into manus/stys/ and change one line in
%% manus/main.tex (\documentclass{stys/cvpr}).
%%
%% It does NOT own the macros the writing skills emit. Those — \todo above all,
%% plus \parahead, \cmark, \tablestyle, \figref, and friends — live in
%% manus/stys/stage.sty, which main.tex loads next and which survives the swap.
%% Keep that split: anything a section or table file writes belongs in the
%% package, anything only the page look needs belongs here.
%%
%% Class options
%%   onecolumn | twocolumn   forwarded to article (default onecolumn)
%%   anon                    render the title panel anonymously: authors become
%%                           "Anonymous Authors"; affiliations, contribution
%%                           notes, and the links row are suppressed
%%   everything else         forwarded to article unchanged (e.g. 11pt, letterpaper)
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{stys/arxiv}[2026/08/03 STAGE preprint class]

%% ---------------------------------------------------------------------------
%% Options
%% ---------------------------------------------------------------------------
%% `anon` is the PDF half of double-blind. The source half is execs/scpts/lint.sh
%% with ANON=true in .env, which fails on identity anywhere under manus/ —
%% comments included, because comments ship with a source upload. The two are
%% deliberately independent: this option hides what the panel would print, the
%% lint rule keeps it out of the files in the first place.
\newif\ifsa@anon
\sa@anonfalse
\DeclareOption{anon}{\sa@anontrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass{article}

%% ---------------------------------------------------------------------------
%% Page and typography
%% ---------------------------------------------------------------------------
\RequirePackage[top=2.25cm,bottom=2.75cm,left=2.5cm,right=2.5cm,columnsep=0.7cm]{geometry}
\RequirePackage{textcomp}
\RequirePackage{lmodern}
\RequirePackage{microtype}
\RequirePackage{placeins}
\RequirePackage{hyphenat}
\RequirePackage{setspace}
\RequirePackage{parskip}
\RequirePackage{etoolbox}
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage[english]{babel}

\renewcommand*\ttdefault{cmvtt}
\renewcommand*\sfdefault{phv}
\DisableLigatures[f]{family=sf*}

%% ---------------------------------------------------------------------------
%% Math, floats, lists, algorithms
%% ---------------------------------------------------------------------------
%% The content-level packages here are loaded again by stys/stage.sty, which has
%% to stand on its own under a venue class. A second \RequirePackage of an
%% already-loaded package is a no-op; the order that matters is fixed here,
%% where amsmath must precede cleveref.
\RequirePackage{amsmath,amsfonts,amssymb,mathtools}
\RequirePackage{bm}
\RequirePackage{xspace}
\RequirePackage{graphicx}
\RequirePackage{subcaption}
\RequirePackage{booktabs}
\RequirePackage{array}
\RequirePackage{tabularx}
\RequirePackage{multirow}
\RequirePackage{makecell}
\RequirePackage{colortbl}
\RequirePackage{nicematrix}
\RequirePackage{siunitx}
\RequirePackage{enumitem}
\RequirePackage{pifont}
\RequirePackage{algorithm}
\RequirePackage{algpseudocode}

%% Algorithm line numbers read <algorithm>.<line>, so a line label is
%% self-locating: \ref on it resolves across algorithms without naming one.
\makeatletter
\renewcommand{\theALG@line}{\thealgorithm.\arabic{ALG@line}}
\renewcommand{\theHALG@line}{\thealgorithm.\arabic{ALG@line}}
\makeatother

\setlist[itemize]{leftmargin=*,itemsep=2pt,topsep=3pt}
\setlist[enumerate]{leftmargin=*,itemsep=2pt,topsep=3pt}
\renewcommand{\algorithmicrequire}{\textbf{Input:}}
\renewcommand{\algorithmicensure}{\textbf{Output:}}

%% \algref{alg:x} prints "Algorithm 2"; \algref{alg:x}{ln:y} prints "Algorithm
%% 2.3", the line label's own number — algorithmicx's \ref{#1}.\ref{#2} would
%% print the algorithm number twice now that a line label already carries it.
%% The algorithm label stays in the call so the two forms read alike at the call
%% site and a stale line label is easy to spot. stage.sty provides the one-
%% argument form for venue classes that ship no algorithm support, so section
%% prose reads the same either way.
\makeatletter
\renewcommand{\algref}[1]{\@ifnextchar\bgroup{\sa@algline@ref{#1}}{Algorithm~\ref{#1}\xspace}}
\newcommand{\sa@algline@ref}[2]{Algorithm~\ref{#2}\xspace}
\makeatother

%% ---------------------------------------------------------------------------
%% Themes
%% ---------------------------------------------------------------------------
%% \papercolor{green|blue|black} recolors headings, links, and the title panel.
%% Table-highlight colors are not here — they are in stage.sty, because a table
%% file that says \rowcolor{LightGreen} must keep compiling after a venue swap.
\RequirePackage[most]{tcolorbox}
\RequirePackage{xcolor}

\definecolor{themegreen}{HTML}{006B4F}
\definecolor{themeblue}{HTML}{0052C7}
\definecolor{themedark}{HTML}{0F6B2A}
\definecolor{fancybg}{HTML}{F0F7F4}
\definecolor{inkfg}{HTML}{1A2E22}
\definecolor{titlefg}{HTML}{1A2E22}
\definecolor{rulecolor}{HTML}{006B4F}
\definecolor{titleframe}{HTML}{BBD8CC}
\definecolor{metabg}{HTML}{E7F2ED}
\definecolor{metalink}{HTML}{006B4F}
\definecolor{simplebg}{HTML}{F3F6F4}
\colorlet{accentcolor}{themegreen}

\makeatletter
\newcommand{\sa@sync@linkcolors}{%
  \@ifpackageloaded{hyperref}{%
    \hypersetup{%
      linkcolor=accentcolor,
      citecolor=accentcolor,
      urlcolor=accentcolor
    }%
  }{}%
}
\newcommand{\sa@theme@green}{%
  \definecolor{themegreen}{HTML}{006B4F}%
  \definecolor{themedark}{HTML}{0F6B2A}%
  \definecolor{fancybg}{HTML}{F0F7F4}%
  \definecolor{inkfg}{HTML}{1A2E22}%
  \definecolor{titlefg}{HTML}{1A2E22}%
  \definecolor{rulecolor}{HTML}{006B4F}%
  \definecolor{titleframe}{HTML}{BBD8CC}%
  \definecolor{metabg}{HTML}{E7F2ED}%
  \definecolor{metalink}{HTML}{006B4F}%
  \definecolor{simplebg}{HTML}{F3F6F4}%
  \colorlet{accentcolor}{themegreen}%
  \sa@sync@linkcolors
}
\newcommand{\sa@theme@blue}{%
  \definecolor{themedark}{HTML}{004BB5}%
  \definecolor{fancybg}{HTML}{F1F7FE}%
  \definecolor{inkfg}{HTML}{172B3A}%
  \definecolor{titlefg}{HTML}{172B3A}%
  \definecolor{rulecolor}{HTML}{0052C7}%
  \definecolor{titleframe}{HTML}{BFD8F5}%
  \definecolor{metabg}{HTML}{E7F1FD}%
  \definecolor{metalink}{HTML}{0052C7}%
  \definecolor{simplebg}{HTML}{F3F7FC}%
  \colorlet{accentcolor}{themeblue}%
  \sa@sync@linkcolors
}
\newcommand{\sa@theme@black}{%
  \definecolor{themedark}{HTML}{111111}%
  \definecolor{fancybg}{HTML}{FFFFFF}%
  \definecolor{inkfg}{HTML}{111111}%
  \definecolor{titlefg}{HTML}{111111}%
  \definecolor{rulecolor}{HTML}{111111}%
  \definecolor{metabg}{HTML}{F3F4F6}%
  \definecolor{metalink}{HTML}{111111}%
  \definecolor{simplebg}{HTML}{F1F2F4}%
  \colorlet{accentcolor}{black}%
  \colorlet{titleframe}{black!22}%
  \sa@sync@linkcolors
}
\newcommand{\papercolor}[1]{%
  \@ifundefined{sa@theme@#1}{%
    \ClassError{stys/arxiv}{Unknown paper color `#1'}{Available colors are green, blue, and black.}%
  }{%
    \csname sa@theme@#1\endcsname
  }%
}
\newcommand{\papertheme}[1]{\papercolor{#1}}
\papercolor{green}
\makeatother

%% ---------------------------------------------------------------------------
%% Links and bibliography
%% ---------------------------------------------------------------------------
\RequirePackage{url}
\RequirePackage{hyperref}
\RequirePackage[noabbrev,nameinlink]{cleveref}
\RequirePackage[numbers,sort&compress]{natbib}

\hypersetup{
  colorlinks,
  linkcolor=accentcolor,
  citecolor=accentcolor,
  urlcolor=accentcolor
}

\def\bibfont{\small}

%% Metadata icons when fontawesome5 is installed, plain text labels when not —
%% a thin TeX install still builds the paper.
\IfFileExists{fontawesome5.sty}{%
  \RequirePackage{fontawesome5}
  \newcommand{\saGithubIcon}{\faGithub}
  \newcommand{\saPlayIcon}{\faPlay}
  \newcommand{\saGlobeIcon}{\faGlobe}
  \newcommand{\saEnvelopeIcon}{\faEnvelope}
  \newcommand{\saCalendarIcon}{\faCalendar}
  \newcommand{\saDatabaseIcon}{\faDatabase}
}{%
  \newcommand{\saGithubIcon}{}
  \newcommand{\saPlayIcon}{}
  \newcommand{\saGlobeIcon}{}
  \newcommand{\saEnvelopeIcon}{}
  \newcommand{\saCalendarIcon}{}
  \newcommand{\saDatabaseIcon}{}
}

%% ---------------------------------------------------------------------------
%% Headings and captions
%% ---------------------------------------------------------------------------
\RequirePackage{titlesec}

\titleformat{\section}
  {\Large\sffamily\bfseries\color{accentcolor}}
  {\thesection}
  {0.6em}
  {}

\titleformat{\subsection}
  {\large\sffamily\bfseries\color{accentcolor}}
  {\thesubsection}
  {0.5em}
  {}

\titleformat{\subsubsection}
  {\normalsize\sffamily\bfseries\color{accentcolor}}
  {\thesubsubsection}
  {0.4em}
  {}

\titlespacing*{\section}{0pt}{3.0ex plus .6ex minus .2ex}{1.5ex plus .25ex}
\titlespacing*{\subsection}{0pt}{1.6ex plus .35ex minus .2ex}{1.0ex plus .2ex}
\titlespacing*{\subsubsection}{0pt}{1.2ex plus .25ex minus .1ex}{0.5ex}

\RequirePackage{caption}
\DeclareCaptionLabelSeparator{pipe}{\enspace\textcolor{black}{|}\enspace}
\DeclareCaptionFormat{elegant}{{\sffamily\bfseries\color{black}#1#2}{\small\color{black}#3}}
\captionsetup{
  singlelinecheck=false,
  format=elegant,
  labelsep=pipe,
  font=small,
  skip=6pt
}

%% Bold text is set in the sans face — the preprint look this class is after.
%% For a venue that expects serif bold, comment this line out; nothing else
%% depends on it.
\DeclareTextFontCommand{\textbf}{\bfseries\sffamily}

\makeatletter

%% ---------------------------------------------------------------------------
%% Title panel
%% ---------------------------------------------------------------------------
%% Everything the panel prints is collected in the preamble and typeset once by
%% \maketitle:
%%
%%   \title{...}                         the title
%%   \author[1,\ast]{Name}               repeatable; the optional argument keys
%%                                       the superscripts
%%   \affiliation[1]{...}                repeatable
%%   \contribution[\ast]{...}            repeatable footnote-style notes
%%   \abstract{...}                      a command, not an environment — so the
%%                                       abstract section file is \input in the
%%                                       preamble, not in the body
%%   \keywords{...}
%%   \code{url} \project{url} \dataset{url} \correspondence{...} \paperdate{...}
%%                                       the links row; \metadata[label]{value}
%%                                       adds an arbitrary one
%%   \paperstyle{fancy|simple}           framed panel or flat panel
%%   \papercolor{green|blue|black}       theme
\newcommand{\sa@title}{Untitled Paper}
\newcommand{\sa@authorlist}{}
\newcommand{\sa@affiliationlist}{}
\newcommand{\sa@contributionlist}{}
\newcommand{\sa@abstract}{}
\newcommand{\sa@keywords}{}
\newcommand{\sa@metadatalist}{}
\newcommand{\sa@metadatasep}{\par\vspace{0.15em}}
\newcommand{\sa@paperstyle}{fancy}
\newcommand{\sa@authorsep}{,\hspace{0.25em}}
\newcommand{\sa@affiliationsep}{\hspace{0.15em}\textcolor{titlefg}{\textperiodcentered}\hspace{0.15em}}
\newcommand{\sa@contributionsep}{,\enspace}
\newlength{\sa@keywordsTopSkip}
\setlength{\sa@keywordsTopSkip}{0.22cm}
\newsavebox{\sa@titlebox}
\newsavebox{\sa@abstractbox}

\newcommand{\sa@sups}[1]{\ifblank{#1}{}{\textsuperscript{\ensuremath{#1}}}}
\newcommand{\sa@authorfont}{\normalsize\sffamily\bfseries\color{titlefg}}
\newcommand{\sa@authorformat}[2][]{%
  {\sa@authorfont#2\sa@sups{#1}}%
}
\newcommand{\sa@affiliationformat}[2][]{%
  {\small\color{titlefg}\sa@sups{#1}#2}%
}
\newcommand{\sa@contributionformat}[2][]{%
  {\small\color{titlefg}\sa@sups{#1}\textit{#2}}%
}
\newcommand{\sa@metadataformat}[2][]{%
  {\small\sffamily\color{titlefg}\ifblank{#1}{}{\textbf{#1}\enspace}#2}%
}

\renewcommand{\title}[1]{\gdef\sa@title{#1}}
\renewcommand{\author}[2][]{%
  \ifdefempty{\sa@authorlist}
    {\gdef\sa@authorlist{\sa@authorformat[#1]{#2}}}
    {\gappto\sa@authorlist{\sa@authorsep\sa@authorformat[#1]{#2}}}%
}
\newcommand{\affiliation}[2][]{%
  \ifdefempty{\sa@affiliationlist}
    {\gdef\sa@affiliationlist{\sa@affiliationformat[#1]{#2}}}
    {\gappto\sa@affiliationlist{\sa@affiliationsep\sa@affiliationformat[#1]{#2}}}%
}
\newcommand{\contribution}[2][]{%
  \ifdefempty{\sa@contributionlist}
    {\gdef\sa@contributionlist{\sa@contributionformat[#1]{#2}}}
    {\gappto\sa@contributionlist{\sa@contributionsep\sa@contributionformat[#1]{#2}}}%
}
\renewcommand{\abstract}[1]{\gdef\sa@abstract{#1}}
\newcommand{\keywords}[1]{\gdef\sa@keywords{#1}}
\newcommand{\metadata}[2][]{%
  \ifdefempty{\sa@metadatalist}
    {\gdef\sa@metadatalist{\sa@metadataformat[#1]{#2}}}
    {\gappto\sa@metadatalist{\sa@metadatasep\sa@metadataformat[#1]{#2}}}%
}

\newcommand{\sa@metalabel}[2]{#1~#2}
\newcommand{\sa@metadataurl}[1]{\href{#1}{\textcolor{metalink}{\nolinkurl{#1}}}}
\newcommand{\email}[1]{\href{mailto:#1}{\textcolor{metalink}{\texttt{#1}}}}
\newcommand{\code}[1]{\metadata[\sa@metalabel{\saGithubIcon}{Code:}]{\sa@metadataurl{#1}}}
\newcommand{\demo}[1]{\metadata[\sa@metalabel{\saPlayIcon}{Demo:}]{\sa@metadataurl{#1}}}
\newcommand{\project}[1]{\metadata[\sa@metalabel{\saGlobeIcon}{Project:}]{\sa@metadataurl{#1}}}
\newcommand{\dataset}[1]{\metadata[\sa@metalabel{\saDatabaseIcon}{Data:}]{\sa@metadataurl{#1}}}
\newcommand{\correspondence}[1]{\metadata[\sa@metalabel{\saEnvelopeIcon}{Contact:}]{#1}}
\newcommand{\paperdate}[1]{\metadata[\sa@metalabel{\saCalendarIcon}{Date:}]{#1}}
\renewcommand{\date}[1]{\paperdate{#1}}

\newcommand{\paperstyle}[1]{%
  \@ifundefined{sa@maketitle@#1}{%
    \ClassError{stys/arxiv}{Unknown paper style `#1'}{Available styles are fancy and simple.}%
  }{%
    \gdef\sa@paperstyle{#1}%
  }%
}

%% Anonymity, applied at \maketitle so it wins over whatever the preamble set.
%% A manuscript with no \author at all also lands here: the panel says
%% "Anonymous Authors" rather than printing an empty author line, which is the
%% state a fresh STAGE skeleton is in.
\newcommand{\sa@applyanon}{%
  \ifsa@anon
    \gdef\sa@authorlist{\sa@authorformat{Anonymous Authors}}%
    \gdef\sa@affiliationlist{}%
    \gdef\sa@contributionlist{}%
    \gdef\sa@metadatalist{}%
  \else
    \ifdefempty{\sa@authorlist}
      {\gdef\sa@authorlist{\sa@authorformat{Anonymous Authors}}}{}%
  \fi
}

\newcommand{\sa@titleblock@typography}{%
  \renewcommand{\sa@authorformat}[2][]{%
    {\sa@authorfont##2\sa@sups{##1}}%
  }%
  \renewcommand{\sa@affiliationformat}[2][]{%
    {\small\rmfamily\color{titlefg}\sa@sups{##1}##2}%
  }%
  \renewcommand{\sa@contributionformat}[2][]{%
    {\small\rmfamily\color{titlefg}\sa@sups{##1}\textit{##2}}%
  }%
  \renewcommand{\sa@metadataformat}[2][]{%
    {\small\color{titlefg}\ifblank{##1}{}{{\sffamily\bfseries ##1}\enspace}##2}%
  }%
  \renewcommand{\sa@authorsep}{,\hspace{0.25em}}%
  \renewcommand{\sa@affiliationsep}{\hspace{0.15em}\textcolor{titlefg}{\textperiodcentered}\hspace{0.15em}}%
  \renewcommand{\sa@contributionsep}{,\enspace}%
  \renewcommand{\sa@metadatasep}{\par\vspace{0.10em}}%
}

\newcommand{\sa@simple@titleblock@typography}{%
  \renewcommand{\sa@authorformat}[2][]{%
    {\sa@authorfont##2\sa@sups{##1}}%
  }%
  \renewcommand{\sa@affiliationformat}[2][]{%
    {\normalsize\rmfamily\color{titlefg}\sa@sups{##1}##2}%
  }%
  \renewcommand{\sa@contributionformat}[2][]{%
    {\normalsize\rmfamily\color{titlefg}\sa@sups{##1}##2}%
  }%
  \renewcommand{\sa@metadataformat}[2][]{%
    {\normalsize\color{titlefg}\ifblank{##1}{}{{\sffamily\bfseries ##1}\enspace}{\normalfont\rmfamily ##2}}%
  }%
  \renewcommand{\sa@authorsep}{,\hspace{0.25em}}%
  \renewcommand{\sa@affiliationsep}{,\enspace}%
  \renewcommand{\sa@contributionsep}{,\enspace}%
  \renewcommand{\sa@metadatasep}{\par\vspace{0.10em}}%
}

\newcommand{\sa@fancydivider}{%
  {\color{rulecolor!85}\rule{\linewidth}{0.65pt}}\par\vspace{-\parskip}%
}

\newcommand{\sa@fancymetadivider}{%
  {\color{rulecolor!55}\rule{\linewidth}{0.45pt}}\par\vspace{-\parskip}%
}
\newlength{\sa@fancyAbstractDividerSkip}
\setlength{\sa@fancyAbstractDividerSkip}{0.20cm}
\newlength{\sa@fancyAbstractLowerDividerSkip}
\setlength{\sa@fancyAbstractLowerDividerSkip}{-0.10cm}

\newcommand{\sa@titlefont}{\huge\sffamily\bfseries\color{titlefg}}
\newcommand{\sa@compacttitlefont}{\LARGE\sffamily\bfseries\color{titlefg}}
\newlength{\sa@titleheightlimit}
\newcommand{\sa@settitlebox}[1]{%
  \setbox\sa@titlebox=\vbox{%
    \hsize=\linewidth
    \parindent=0pt
    #1%
    \global\sa@titleheightlimit=2.75\baselineskip
    \raggedright
    \nohyphens
    \strut\sa@title\strut\par
  }%
}
%% A title that would run past three lines drops one font size instead of
%% pushing the panel down the page.
\newcommand{\sa@printtitle}{%
  \begingroup
    \sa@settitlebox{\sa@titlefont}%
    \ifdim\dimexpr\ht\sa@titlebox+\dp\sa@titlebox\relax>\sa@titleheightlimit
      \sa@settitlebox{\sa@compacttitlefont}%
    \fi
    \box\sa@titlebox
  \endgroup
}
\newcommand{\sa@setabstractbox}{%
  \setbox\sa@abstractbox=\vbox{%
    \hsize=\linewidth
    \parindent=0pt
    \setstretch{1.08}%
    \small\rmfamily\color{inkfg}\sa@abstract\par
  }%
}
\newcommand{\sa@printabstract}{%
  \begingroup
    \sa@setabstractbox
    \box\sa@abstractbox
  \endgroup
}

\newcommand{\sa@maketitle@fancy}{%
  \begingroup
    \sa@titleblock@typography
    \begin{tcolorbox}[
      enhanced,
      colback=fancybg,
      colframe=titleframe,
      boxrule=0.45pt,
      arc=10pt,
      boxsep=0pt,
      left=0.7cm,
      right=0.7cm,
      top=0.45cm,
      bottom=0.45cm,
      before skip=0pt,
      grow to left by=1pt,
      grow to right by=1pt,
      drop fuzzy shadow={black!10!white}
    ]
      {%
        \raggedright
        \nohyphens
        {\noindent\sa@printtitle\par}
        \vskip 0.20cm
        {\setstretch{1.0}\normalsize\sa@authorlist\par}
        \ifdefempty{\sa@affiliationlist}{}{%
          \vskip 0.20cm
          {\sa@affiliationlist\par}
        }
        \ifdefempty{\sa@contributionlist}{}{%
          \vskip 0.20cm
          {\sa@contributionlist\par}
        }
      }%
      \ifdefempty{\sa@abstract}{}{%
        \vskip 0.10cm
        \sa@fancydivider
        \vskip\sa@fancyAbstractDividerSkip
        \sa@printabstract
      }
      \ifdefempty{\sa@keywords}{}{%
        \vskip 0.10cm
        {\normalsize\sffamily\textbf{\color{titlefg}Keywords:}\enspace\color{titlefg}\sa@keywords\par}
      }
      \ifdefempty{\sa@metadatalist}{}{%
        \ifdefempty{\sa@abstract}{%
          \vskip 0.10cm
        }{%
          \ifdefempty{\sa@keywords}{%
            \vskip\sa@fancyAbstractLowerDividerSkip
          }{%
            \vskip 0.10cm
          }%
        }%
        \sa@fancymetadivider
        \vskip 0.10cm
        \begin{tcolorbox}[
          enhanced,
          frame hidden,
          colback=metabg,
          arc=5pt,
          boxsep=0pt,
          left=0.22cm,
          right=0.22cm,
          top=0.09cm,
          bottom=0.09cm
        ]
          {\setstretch{1.0}\sa@metadatalist\par}
        \end{tcolorbox}
      }
    \end{tcolorbox}
  \endgroup
  \tcbset{reset}
  \FloatBarrier
}

\newcommand{\sa@maketitle@simple}{%
  \begingroup
    \sa@simple@titleblock@typography
    \renewcommand{\sa@metalabel}[2]{##2}%
    \begin{tcolorbox}[
      enhanced,
      frame hidden,
      colback=simplebg,
      arc=10pt,
      boxsep=0pt,
      left=0.7cm,
      right=0.7cm,
      top=0.45cm,
      bottom=0.45cm,
      before skip=0pt,
      grow to left by=1pt,
      grow to right by=1pt
    ]
      {%
        \raggedright
        \nohyphens
        {\noindent\sa@printtitle\par}
        \vskip 0.20cm
        {\setstretch{1.0}\normalsize\sa@authorlist\par}
        \ifdefempty{\sa@affiliationlist}{}{%
          \vskip 0.20cm
          {\setstretch{1.0}\sa@affiliationlist\par}
        }
        \ifdefempty{\sa@contributionlist}{}{%
          \vskip 0.20cm
          {\setstretch{1.0}\sa@contributionlist\par}
        }
      }%
      \ifdefempty{\sa@abstract}{}{%
        \vskip 0.30cm
        \sa@printabstract
      }
      \ifdefempty{\sa@keywords}{}{%
        \vskip 0.10cm
        {\normalsize\sffamily\textbf{\color{titlefg}Keywords:}\enspace\color{titlefg}\sa@keywords\par}
      }
      \ifdefempty{\sa@metadatalist}{}{%
        \vskip 0.30cm
        {\setstretch{1.0}\sa@metadatalist\par}
      }
    \end{tcolorbox}
  \endgroup
  \tcbset{reset}
  \FloatBarrier
}

\newcommand{\sa@maketitle}{%
  \csname sa@maketitle@\sa@paperstyle\endcsname
}

\renewcommand{\maketitle}{%
  \sa@applyanon
  \hypersetup{pdftitle={\sa@title}}%
  \if@twocolumn
    \twocolumn[\sa@maketitle\vskip 0.4cm]%
  \else
    \sa@maketitle
  \fi
}

%% Appendix divider. Appendix sections keep STAGE's secs/<n>_<slug>.tex naming
%% and numbering, continuing after the last main-body section; \appendix then
%% relabels them A, B, C.
\newcommand{\beginappendix}{%
  \appendix
  \section*{Appendix}
  \addcontentsline{toc}{section}{Appendix}
}

\makeatother
