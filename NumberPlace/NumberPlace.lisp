;;;; last updated : 2026-07-19 11:05:32(JST)
;;;;
;;;;  ナンバープレイス(ナンプレ)の解法過程の表示と盤面変化検討および手筋習得練習のためのプログラム。
;;;;
;;;;  Licenced under GNU Library General Public Licence.
;;;;  Copyright (C) 2001-2025 Isao Daigo (daigo@tkf.att.ne.jp).
;;;;
;;;;  https://drive.google.com/drive/folders/1ZTZrYjWAFheIjF-gxRM-Shicmn9YD1Rp?usp=sharing
;;;;
;;;;  Common Lispで記述してあるので実行にはCommon Lispの処理系が必要です。開発と動作確認は
;;;;  Ubuntu版のGNU CLISPとSteel Bank Common Lispで行っています。
;;;;
;;;;  CLISPの最新版は以下のリンクからダウンロードできます。
;;;;  CLISP     http://clisp.cons.org/
;;;;
;;;;  Steel Bank Common Lispの最新版は以下のリンクからダウンロードできます。
;;;;  sbcl      https://www.sbcl.org/platform-table.html
;;;;
;;;;  処理系を実行後、処理系のプロンプトから本プログラムをロードします。本プログラムを
;;;;  /home/daigo/Lisp/NumberPlaceに置いているのであれば次のようにします。
;;;;
;;;;    > cd /home/daigo/Lisp/NumberPlace
;;;;    > (compile-file "NumberPlace.lisp")
;;;;    > (load "NumberPlace.fas")  ;; CLISPの場合。sbclでは(load "NumberPlace.fasl")
;;;;
;;;;  コンパイル作業=(compile-file "NumberPlace.lisp")は最初の1回だけです。
;;;;  2回目以降はコンパイル済みなので (load "NumberPlace.fas") または (load "NumberPlace.fasl")
;;;;  のみです。上手く行かない場合はコンパイラのパスが通っていないと思われますので、別途 readme.txt
;;;;  をご覧ください。
;;;;
;;;;  ===============================================================================
;;;;  Ver.6.0.0から任意の盤面で適用可能な手筋を提示して、ユーザが選択した手筋を使って盤面を
;;;;  進める機能を追加しました。一度通過したルートは任意の位置に逆戻り可能です。この機能に
;;;;  よって任意の盤面で異なる手筋を選択した場合の変化を検討可能になります。
;;;;
;;;;    (examin sample-board-5)
;;;;
;;;;  のように使います。他の機能を含めてメニューからの選択式です。
;;;;
;;;;  NumberPlace.lispが使用する手筋はユーザが選択した手筋と制限の範囲で適用されます。
;;;;  関数[examin]の中では試行錯誤法は使いません。
;;;;
;;;;  ユーザが設定した手筋の全ての順序の組み合わせを実行することで全ての解き筋をリストアップする
;;;;  機能も追加しています。ただし難しい問題の場合、盤面変化数が数十万以上になることもあり、高速
;;;;  なCPUでも数時間以上を要する可能性があります。ご注意下さい。
;;;;
;;;;    (find-all-logical-path sample-board-5)
;;;;
;;;;  のように使いますが、隠しコマンドを解除すると関数[examin]のメニューからも使えます。
;;;;  ===============================================================================
;;;;
;;;;  各種の動作設定が可能ですが、お勧めは使用を許可する手筋とレベルを設定しておいて
;;;;  から「teach」という関数を実行することです。
;;;;
;;;;    > (machine-level)
;;;;    > (teach sample-board-6)
;;;;
;;;;  とすると添付例題の「sample-board-6」の解法過程を表示します。
;;;;
;;;;  解法過程の表示設定を指定する場合は
;;;;
;;;;            > (teach sample-board-6 11)
;;;;
;;;;    とオプションの第2引数で指定します。10の位が盤面表示レベル、1の位が解説文表示レベルです。
;;;;
;;;;    [0]=解法手順出力なし。[1]=既定の解説のみ。[2]=全ての解説。
;;;;
;;;;  標準は「11」です。その他の概要は関数
;;;;
;;;;    > (help)
;;;;
;;;;  を実行すると表示されます。実装している手筋は以下のとおりです。
;;;;  
;;;;  ・基本手筋(hidden single。行・列・ブロック・ハウス内で唯一の候補なら確定値）
;;;;  ・セル・ユニーク(グループ内で唯一可能な確定値) → 基本手筋(do-fundamental)に統合
;;;;  ・ローカライゼーション
;;;;  ・tuples(n国同盟=無制限)
;;;;  ・n-grid(x-wing, swordfish, jellyfish,...の一般形)
;;;;  ・配置確定法(Pattern Overlay Method)
;;;;  ・Nice Loop(連鎖セル数=無制限)
;;;;  ・Advanced Coloring(Simple Colors, Multi-Colorsを統合した手筋)
;;;;  ・Almost Locked Set(=ALS。-Wing, XYZ-Wing, Sue De CoqなどWing系手筋の一般形)
;;;;  ・Grid-Based Almost Locked Set(=Sashimi Fish, Finned Fishの一般形)
;;;;  ・試行錯誤(仮置き)法
;;;;
;;;;  以上の手筋とその適用レベルは個別に設定できますが、ユーザのナンプレのレベルに合わせて
;;;;  お勧めのパラメータをまとめて設定する関数をいくつか用意しています。
;;;;  
;;;;    ※ナンプレ初心者向きの設定 = (novice-level)
;;;;    基本手筋=許可, その他手筋=不使用。
;;;;
;;;;    ※ナンプレ初級から中級者向きの設定 = (middle-level)
;;;;    localization=使用, tuples=2国同盟まで使用。
;;;;
;;;;    ※ナンプレ中級から上級者向きの設定 = (senior-level)
;;;;    localization=使用, n-grid=x-wingまで使用, tuples=3国同盟まで使用。
;;;;
;;;;    ※ナンプレ上級者向きの設定 = (advanced-level)
;;;;    localization=使用, n-grid=swordfishまで使用, tuples=3国同盟まで使用, 配置確定法=使用,
;;;;    ALS=使用, Nice Loop=連鎖セル数上限3で使用。
;;;;
;;;;    ※ナンプレ超上級者向きの設定 = (machine-level)
;;;;    localization=使用, n-grid=上限なしで使用, tuples=上限なしで使用, 配置確定法=使用,
;;;;    Nice Loop=連鎖セル数上限なし。Advanced Coloring=使用。ALS=使用。cheat=許可。複数解=探索せず。
;;;;
;;;;  ユーザが自分で適用できるレベルの手筋に限定して解法手順を追うことが出来るようにしています。
;;;;
;;;;  ただし、候補の刈り込みが不十分な状態で探索を進めると解を得られない場合があります。その場
;;;;  合は「(chain-trim t)」として再帰的な刈り込みを許可してください。既定の設定では再帰的な刈り
;;;;  込みは許可する設定になっています。
;;;;
;;;;  上述の手筋だけでは解が得られない場合は試行錯誤関数による仮置きが行われて再び上述の手筋に
;;;;  よる解の探索が続きます。試行錯誤(仮置き)法を備えているので問題が解を持つ限り複数解を含め
;;;;  て解けない問題は存在しません。
;;;;
;;;;  ホームディレクトリに「NumberPlace-init.lisp」というファイルがあると初期設定ファイルと
;;;;  して起動時に最初に読み込みます。各種パラメータの初期値などを指定したい場合に使用します。
;;;;
;;;;  プログラム中で使用している用語の定義は以下の通りです。
;;;;
;;;;    ボード		::=     ナンバープレースで使用する9x9のマス目を持つ盤。
;;;;    セル		::=     盤上のマス目のこと。
;;;;    行		::=     ボード上の横方向のセルの連なり。一番上が0行目、一番下が8行目。
;;;;    列		::=     ボード上の縦方向のセルの連なり。一番左が0列目、一番右が8列目。
;;;;    ブロック	::=     ボード上の3x3のセルの集合。左から右、上から下の順で0番から8番。
;;;;    グループ	::=     行・列・ブロックの和集合。ユニット、ピアも同義語。
;;;;
;;;;    ※解法手順の出力とボードの入力では、一番上の行を1行目、左端の列を1列目、
;;;;    左上のブロックを第1ブロックとしています。
;;;;
;;;;   Copyright 2011-2024 Isao Daigo, 著作権は GNU GPL3 に従います。
;;;;
;;;;   This program is free software: you can redistribute it and/or modify it under the terms
;;;;   of the GNU General Public License as published by the Free Software Foundation, either
;;;;   version 3 of the License, or (at your option) any later version.
;;;;
;;;;   This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
;;;;   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;;;;   See the GNU General Public License for more details.
;;;;
;;;;   You should have received a copy of the GNU General Public License along with this program.
;;;;   If not, see <https://www.gnu.org/licenses/>.
;;;;
;;;;  Ver.1.2.1 determin-possibility-list-in-row,col,blockを修正。
;;;;       1.2.2 冗長な処理を最適化。
;;;;       1.2.3 関数の論理的関係を整理。ボードの出力サイズを調整。
;;;;       1.2.4 関数を整理。determin-possibility系を削除。trim系に集約。
;;;;       1.2.5 小さなサイズでボードを出力する設定 (print-small t) を追加。
;;;;       1.2.6 9x9以外のボードも処理可能なように修正。
;;;;       1.2.7 print-smallをprint-miniに変更。通常サイズ・ボードの出力形式を変更。
;;;;             ボード上の指定のマスが指定の値、または唯一の値(仮置き含む)に絞り込まれたら
;;;;             その瞬間のボードの状態を出力するsnap-shot機能を追加。
;;;;       1.3.0 localization系とnaked系の手筋を追加実装。
;;;;       1.4.0 x-wingを実装。その他改訂多数。
;;;;       1.4.1 do-trim-blockのバグを修正。
;;;;       1.5.0 x-wingを削除。do-level-2-trimを実装。
;;;;       1.5.1 help, novice-level, middle-level, senior-level, advanced-levelなどを追加。
;;;;       1.6.0 グリッド解析(n-grid)を実装。do-level-2-trimをdo-fix-unmovedに改名
;;;;       1.6.1 do-localizationでrow-gridに対する処理を追加&バグ修正。
;;;;       1.7.0 do-tuples(n国同盟)を実装。do-localizationと競合する問題が発生。
;;;;       1.7.1 pencil-mark設定を追加。1.7.0の競合問題解決。消す手筋の直前には刈り込みが必要。
;;;;       1.7.2 do-n-gridを修正。
;;;;       1.7.3 do-n-gridを修正。各解法過程の難易度をグラフ表示する「plot」機能を追加。
;;;;       1.7.4 手筋の適用順序を変更。易しい手筋が適用できる限り易しい手筋を適用する。
;;;;             処理系間(CLISPとSBCL)の互換性を確保(format出力関連)。
;;;;       1.8.0 指定した手数先読みして「最善」の手筋を選択するモードを追加。
;;;;       1.8.2 ブロック内に対するローカライゼーション処理を追加。手筋適用方法を選択可能に。
;;;;       1.8.3 16x16の盤面のローカライゼーションで問題が発生するバグを修正。
;;;;       1.9.0 配置確定法を拡張。有効な配置パターンに現れないセル位置から候補を削除可能に。
;;;;       2.0.0 Nice Loopを実装。
;;;;       2.0.1 find-same-labelとfind-same-candidateの手順解釈を修正。
;;;;       2.0.2 find-nice-loop-subのNice Loop探索方法を修正。
;;;;             結論が同じNice Loopは連鎖数が短いものだけを採用。
;;;;       2.1.0 max-nice-loopsを追加。各盤面で採用するNice Loop最大経路数を設定可能に。
;;;;       2.1.1 関数[insert-new-page]を削除。盤面出力を一時停止する関数[pause]を追加。
;;;;       2.1.2 手筋適用回数，平均難易度，最大難易度，合計難易度の結果表示を追加。
;;;;             関数[cells-in-use-p]と[do-nice-loop]を修正。関数[enter-board]を修正。
;;;;             関数[permit-methods-search]を[think-depth]に改名。
;;;;       2.1.3 盤面中の「空白文字」を指定できるように修正。(space-char-is ".")でピリオドに。
;;;;             HTML表示系で連続する空白がひとつの空白に縮約される場合への対応。
;;;;       2.1.4 盤面中の「空数字」位置に関数[space-char-is]で指定した文字を表示するように変更。
;;;;       2.1.5 関数[pause]のバグ修正(2009/06/26)。
;;;;       3.0.0 Advanced Coloringを実装(2010/11/25)。
;;;;             理詰めだけで解に到達できる手筋のリストを返す関数[find-logical-path]を実装。
;;;;             用意されているどの手筋でも手を進められない盤面を発見したときは[(evil-boards)]
;;;;             で呼び出せる。[do-logical-path]でパスにしたがった再実行可能。
;;;;       3.0.1 関数[coloring-cell]の不具合修正(2010/12/22)
;;;;       3.0.2 関数[coloring-cell]の不具合修正(2010/12/31)
;;;;       3.0.4 細かな修正(2011/01/02)
;;;;       3.0.9 関数[expand-cluster]を[do-coloring]に統合(2011/01/24)
;;;;       3.1.0 関数[block-except]の不具合修正(2011/06/05)。削除できなかった候補数字が存在した可能性。
;;;;       4.0.0 Almost Locked Setを実装(2011/06/09)
;;;;       5.0.0 Grid-Based Almost Locked Setを実装(2011/06/21)
;;;;       5.0.2 reduce-ALS-listとreduce-GB-ALS-listの不具合を修正(2011/06/27)。
;;;;       5.0.3 表示不都合に関連してprintable-elimination-listを修正(2011/06/29)。
;;;;             不連続Nice Loop表示等で[r2c8<>2]となるべきが[r2c8<>(2)]などと表示されていたのを修正。
;;;;       5.0.4 Localizationとn-gridでの削除可能候補を[@]で表示するように改善(2011/07/08)。
;;;;       5.0.5 関数[enter-board]の表示を調整(2011/07/10)。
;;;;       5.0.6 関数[print-normal]をセル単位でも彩色可能に拡張(2011/07/23)。
;;;;       5.0.7 関数[set-colored-cell]と[set-colored-candidate]を追加(2011/07/24)。
;;;;       5.0.8 関数[do-almost-locked-set]と[do-GB-ALS]の解説盤面をカラー表示可能に(2011/07/25)。
;;;;       5.0.9 実装しているすべての手筋の解説盤面をカラー表示可能に(2011/08/01)。
;;;;             A: (color-mode 0) & (show-color-board nil) ==> 解説盤面はモノクロのミニ・ボード。
;;;;             B: (color-mode 0) & (show-color-board t)   ==> 解説盤面はモノクロの標準ボード。
;;;;             C: (color-mode 1) & (show-color-board nil) ==> 解説盤面はモノクロのミニ・ボード。
;;;;             D: (color-mode 1) & (show-color-board t)   ==> 解説盤面はカラーの標準ボード。記号表示。
;;;;             E: (color-mode 2) & (show-color-board nil) ==> 解説盤面はモノクロのミニ・ボード。
;;;;             F: (color-mode 2) & (show-color-board t)   ==> 解説盤面はカラーの標準ボード。数字表示。
;;;;               ※ Advanced coloringの表示盤面は(color-mode)の値に従って表示される。
;;;;                 (color-mode 0) ==> Advanced coloringの表示盤面はモノクロ。記号表示。
;;;;                 (color-mode 1) ==> Advanced coloringの表示盤面はカラー。記号表示。
;;;;                 (color-mode 2) ==> Advanced coloringの表示盤面はカラー。数字表示。
;;;;               ※ (color-mode 1)と(color-mode 2)でのカラー表示にはxterm 256 color互換端末が必要。
;;;;             A...Fで選択できるようにする関数[sel]を用意。(sel #\d)でDを選択。引数なしで対話的選択。
;;;;       5.1.0 ANSI端末に対応(8色)。関数[xcolor-mode]を[color-type]に改名。(2011/08/05)
;;;;       5.2.0 指定された手筋群の全ての適用順序の組み合わせによって得られる全ての解き筋を得る
;;;;                関数[find-all-logical-path]を実装。
;;;;       6.0.0 任意の盤面に対して使用可能な全ての手筋を示し、選択した手筋で検討を進める機能 [examin]を
;;;;             追加。一度通過したルートは逆戻り可能。(2023-12-13)
;;;;       6.1.0 判明している解き筋/解決済み解き筋を表示する機能を追加。
;;;;       6.2.0 一定画面数出力ごとに一時停止する関数[pause]を一部修正して関数[examin]のメニューから利用
;;;;             出来るように修正。これに伴って[examin]関数のメニュー[P)rint]は[I)nformation]に変更。
;;;;             [pause]関数へのキー割り当てを[P)ause]とした。
;;;;       6.2.3 軽微な修正。
;;;;       6.3.5 アルゴリズムの整理と複数の修正。
;;;;       6.4.1 複数の修正と画面出力の改善。
;;;;       6.4.3 複数の修正と画面出力の改善。
;;;;       6.4.5 関数[examin]のメニュー項目の[N)ode]を削除して[I)nformation]に統合した。
;;;;       6.5.4 Auto saveと一時停止機能を分離した。Dead Endルートと通常ルートの表示を分けた。
;;;;       6.6.0 途中経過情報を持つルート・ノードを保存する際に最大ノード番号を保存していたが、これを
;;;;             廃止して、読み込んだデータから最大ノード番号を復元するようにした。
;;;;       6.7.0 関数[examin]のメニュー項目の[Load]の機能拡張と盤面データをファイルに追記する
;;;;             [>>]コマンドを追加した。
;;;;       6.7.8 複数のバグ修正と用語の統一。
;;;;       6.8.1 Routeコマンドで孫ノード以降までの解法ルートを表示できるようにした。スペルミスを訂正した。
;;;;       6.8.3 引数を指定せずに[examin]関数を実行した場合の挙動を変更した。[enter-board]関数による
;;;;             盤面データの入力モードにならない。盤面設定は[N)ew Game]コマンドで行う。
;;;;       6.8.4 GNU CLISPとSteel Bank Common Lisp(SBCL)のyes-or-no-p/y-or-n-pの動作を一致させる
;;;;		 ためにquery-yes-or-no-p/query-y-or-n-p関数を定義して使うこととした。
;;;;             その他、両Common Lisp処理系の動作を一致させるための修正を行った。
;;;;       6.8.5 SBCLで最適化レベルを高くした場合でもCLISPと動作が一致するように修正を行った。
;;;;       6.8.6 メニューのコマンド名をフルスペルでも受け付けるようにした。
;;;;             処理系依存機能の[dribble]を使用可能な処理系で使えるようにした。
;;;;             正常に動作する処理系名を[*can-dribble*]に登録する。"CLISP"はOK。"SBCL"は不可。
;;;;       6.8.7 親ノードの盤面データを子ノードに保存しないことに変更した。これによって保存データ
;;;;             を、ほぼ半減できる。その他、メッセージ細部の変更と調整を行った。
;;;;       6.8.8 長い処理の場合に経過時間が分かるようにメニュー・プロンプトに時分秒も表示するようにした。
;;;;       6.9.1 関数[examin]の引数が文字列の場合は、ボード型データのファイル指定と見做すようにした。
;;;;       7.0.0 関数[examin]のメニュー表示の量を3段階で選択できるようにした。
;;;;       7.1.0 解法ルート図の保存用のコマンドをExploreコマンド内から独立させた。
;;;;       7.1.1 解法ルート図の保存時にユーザがファイル名を指定したときは拡張子[.txt]を付けない。
;;;;       7.2.0 (color-mode)が1の場合、コピー＆ペーストで情報をコピーできるよう候補数字を短縮色名
;;;;             で表示するように変更した。その他、処理の厳密化と軽微なバグ修正。2024-01-25
;;;;       7.2.3 ローカライゼーションでのカラー盤面の表示を改善した。
;;;;       7.3.0 矛盾を含む盤面が現れた場合にのみ、情報表示と情報保存用コマンドを表示するようにした。
;;;;       7.4.0 関数[step-around]のメニュー選択結果出力が「少ない」場合はメニュー再表示を省略することにした。
;;;;       7.5.0 セル・ユニーク[do-cell-unique]を基本手筋[do-fundamental]に吸収統合した。
;;;;       7.6.0 手筋に関するヘルプと、それ以外の項目のヘルプを分けた。
;;;;             関数[examin]内のヘルプ・メッセージをトップ・レベルのメニューに戻らずに続けられるようにした。
;;;;       7.6.1 SBCLでリスト出力が不正となる場合があったため部分的にバグ対応のコードで回避した。
;;;;       7.6.2 [examin]を単独実行可能ファイルの開始関数として整合するように改修した(SBCL対応)。
;;;;       7.6.3 [-node型データ]の読み込みと[盤面データ]の読み込みコマンドを分けた。
;;;;             メモリ上のすべての盤面データを一括してファイルに書き出すコマンド[store]を新設した。
;;;;             盤面データは[(setq [name] [body])形式に統一して書き出している。コメントとして
;;;;             盤面図も書き出している。盤面サイズは設定に従う。
;;;;       7.6.4 関数[examin]から関数[step-around]を呼び出している。[step-around]内から[examin]を
;;;;             呼び出している場所があったが、この場合[step-around]の"Quit"コマンドを複数回入力し
;;;;             ないと実際にquit出来なかったので修正した。
;;;;       7.6.5 無名盤面データを読み込む際の名前の与え方を選択できるようにした。
;;;;             名前の一意性を保証するが番号部は制御不能か、名前の一意性を保証できないが連番を保証するか。
;;;;             [create-unique-name]参照。
;;;;       7.7.0 使用可能な処理系で「長い」ヘルプ・メッセージ表示で外部コマンドの"less"を使用できるようにした。
;;;;       7.8.0 各関数の説明をコメントから[describe]用ドキュメント文字列に変更した。
;;;;             関数[do-fix-unmoved]の名前を[do-pattern-overlay-method]に変更した。
;;;;       7.9.0 一部のメニュー入力で先行入力を可能にした(「find 3」でノード3への移動など)。
;;;;       7.9.6 バグ修正。特に関数[do-trim-cell]は削除できている候補を削除しない重大なバグだった。
;;;;       8.0.α セル式、answerコマンド、hintコマンド等を実装。
;;;;       8.1.α 候補数字を部分的に削除できる解答に部分点を与えるように変更した。
;;;;       8.2.0 関数[parse-cell-expression]にcandidateキーワードとdeterminedキーワードを追加した。
;;;;             候補数字が複数存在するセル(確定値でないセル)と確定値であるセルを指定できる。
;;;;             ただしセルの内容を参照する必要があるためオプショナルな第2引数にボード型データが必要。
;;;;       8.3.0 candidateキーワードとdeterminedキーワードの引数部分に「式」を指定できるようにした。
;;;;             ただし式の値は候補数字として許される値であること(内部的には0...*board-size*)。
;;;;       8.3.3 関数[parse-cell-expression]を修正した影響で発生したバグを修正。
;;;;       8.4.0 関数[do-grid-based-almost-locked-set]と[do-advanced-coloring]に対する[guess-game]
;;;;             用のコードが完成。必要なコード全体が一応完成(2024-04-29)。
;;;;       8.5.0 関数[make-prototype-document]を追加した。Common Lispのソースコードを与えると全ての
;;;;             関数に対して、関数名+引数リスト+関数ドキュメントを指定したファイルに出力する。ソートも可。
;;;;             (make-prototype-document "NumberPlace.lisp" "prototype-document.txt" :sort t)で
;;;;             NumberPlace.lisp内の全ての関数の、関数名、引数リスト、関数ドキュメントの最新の一覧が得られる。
;;;;             「:comment t」というキーワード・オプションも追加すると全出力の行頭に「;;」を付加して
;;;;             Common Lispのコメント形式で出力する。
;;;;       8.5.2 関数[answer-for]で予定された入力形式でなければ再入力を求めるように変更した。
;;;;       8.6.1 関数[examin]を引数なしで実行したとき「メモリ上の登録済み盤面データ」から選べるようにした。
;;;;       8.6.4 関数[step-around]内の「ENTER」部分のバグ修正を行った。
;;;;       8.7.0 関数[step-around]内のコマンド名入力に[get-command-full-name]を使うようにした。
;;;;       8.7.5 [get-command-full-name]採用に伴う複数のバグ修正。
;;;;       8.8.0 [print-step-around-menu]の最短文字数位置の表示を自動化した。
;;;;
;;;; 各バージョンによる例題(sample-board-nn)に対する[試行錯誤回数]/[試行錯誤の最大深さ]の推移。
;;;; ---------------------------------------------------------------------------------------------
;;;; バージョン        #01    #02    #03    #04    #05    #06    #07    #08    #09    #10     #11
;;;; ---------------------------------------------------------------------------------------------
;;;; 1.0.0(20081231) 00/00  03/03  23/05  06/03  00/00  73/11  --/--  --/--  --/--  --/--  --/--
;;;; 1.2.1(20090102) 00/00  03/03  23/05  06/03  00/00  73/11  01/01  --/--  --/--  --/--  --/--
;;;; 1.2.3(20090103) 00/00  03/03  23/05  06/03  00/00  73/11  01/01  06/04  --/--  --/--  --/--
;;;; 1.2.7(20090110) 00/00  05/03  24/05  06/03  00/00  73/11  01/01  06/04  --/--  69/08  541/18
;;;; 1.3.0(20090120) 00/00  04/02  04/03  02/02  00/00  24/06  01/01  03/03  14/04  66/08  348/16
;;;; 1.4.0(20090123) 00/00  04/02  04/03  02/02  00/00  24/06  01/01  03/03  14/04  66/08  348/16
;;;; 1.5.1(20090130) 00/00  04/02  04/03  02/02  00/00  24/06  01/01  03/03  14/04  66/08  348/16
;;;; 1.6.0(20090206) 00/00  00/00  00/00  02/02  00/00  22/06  01/01  00/00  09/03  59/07  238/21
;;;; 1.6.1(20090208) 00/00  00/00  00/00  02/02  00/00  15/06  01/01  00/00  05/03  57/07  041/08
;;;; 1.7.0(20090215) 00/00  00/00  00/00  00/00  00/00  02/02  01/01  00/00  03/02  50/07  031/11
;;;; 1.7.1(20090215) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  01/01  50/07  006/02
;;;; 1.7.2(20090216) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  01/01  50/07  004/02
;;;; 1.7.3(20090220) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  01/01  52/07  005/02
;;;; 1.7.4(20090226) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  01/01  52/07  005/02
;;;; 1.8.0(20090303) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  01/01  52/07  005/02
;;;; 1.8.2(20090306) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  00/00  50/07  004/02
;;;; 1.8.3(20090308) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  00/00  50/07  003/02
;;;; 1.9.0(20090321) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  00/00  47/07  003/02
;;;; 2.0.0(20090607) 00/00  00/00  00/00  00/00  00/00  01/01  01/01  00/00  00/00  09/04  002/02
;;;; 2.0.2(20090607) 00/00  00/00  00/00  00/00  00/00  00/00  01/01  00/00  00/00  06/03* 002/02
;;;; 3.0.1(20101214) 00/00  00/00  00/00  00/00  00/00  00/00  01/01  00/00  00/00  02/02  002/02
;;;; 5.0.2(20110627) 00/00  00/00  00/00  00/00  00/00  00/00  01/01  00/00  00/00  02/02  001/01
;;;; ---------------------------------------------------------------------------------------------
;;;;
;;;; top95(http://magictour.free.fr/top95)を実行した際の試行錯誤回数。
;;;;   3.0.1 122回
;;;;   5.0.2 112回(GB-ALSのみ)
;;;;   5.0.2  76回(ALSのみ)
;;;;   5.0.2  66回(ALS+GB-ALS)
;;;;
;;;; ※ 「試行錯誤回数」は試行錯誤関数[do-trial-and-error]の呼び出し回数。
;;;; ※ #07は2個の解を持つので理論的に最低でも1回の試行錯誤が必要。
;;;; ※ #11は16x16のビッグ・ナンプレ。2024年現在、ビッグ・ナンプレの動作検証は行っていない。
;;;; ※ Ver.1.7.0以降の情報は(tuples-limit (floor *board-size* 2))。9x9 ==> 4, 16x16 ==> 8.
;;;; ※ Ver.1.8.0以降の情報は(machine-level nil)。
;;;; ※ Ver.2.0.2の「*」は(think-depth 1)では「05/02」。
;;;; ※ Ver.3.0.0以降は(permit-cheat t)。
;;;;

(defpackage :NumberPlace
  #+clisp  (:use :common-lisp)
  #+sbcl   (:use :common-lisp)
  #+gcl    (:use :lisp)
  (:use :print-color-string)
  (:use :support-functions)
  (:export
   #:advanced-level
   #:auto-trim-level
   #:chain-trim
   #:current-preset-level
   #:edit-board
   #:enter-board
   #:examin
   #:explanation-level
   #:machine-level
   #:max-nice-length
   #:middle-level
   #:n-grid-limit
   #:need-multiple-answer
   #:novice-level
   #:numberplace
   #:numberplace-solver
   #:pause
   #:pencil-mark
   #:permit-cheat
   #:plot
   #:print-board
   #:print-check
   #:print-env
   #:print-mini
   #:print-normal
   #:reset-env
   #:save-env
   #:senior-level
   #:speed-first
   #:stat
   #:teach
   #:tuples-limit
   ) ;; end :export
  ) ;; end defpackage

(in-package :NumberPlace)

(declaim (optimize (safety 0) (speed 3) (space 0) (compilation-speed 0)))
;;(declaim (optimize (safety 3) (speed 0) (space 0) (compilation-speed 0)))

(defparameter *version* "8.8.3")

(defstruct vertex
  (bivalue-cell nil)            ;; Bi-value cellなら[t]。
  (edge-color nil)              ;; GraphVizでリンク・マップを描画する際の辺の色とスタイル。
  (parent nil)                  ;; 候補辺の親ノード。
  (fringe-weight 0)             ;; 縁辺の重み(距離,削除可能候補数,weak link数,strong link数)
  (status 'unseen)              ;; intree/fringe/unseen/passed
  (unseen nil)                  ;; Nice Loop探索時に未訪問セルを管理する。
  (adj-list nil)                ;; 各ノードに隣接するノード(adjacency)のリスト。
)                               ;; [adjeycency list] ::= ([adj-node]...) ;
                                ;; [adj-node] ::= ([vertex] [weight] [inference type] [labels]) ;

(defstruct game-node
  (node-number nil)             ;; 0...[*node-number*]
  (node-label nil)              ;; ユーザが任意で命名し付与するラベル  
  (parent-node-number nil)      ;; ひとつ上のノード番号
  (parent-node-label nil)       ;; ひとつ上のノードのラベル
  (next-node nil)               ;; ひとつ下のノードへのリンク（複数あり得る）
  (prev-methods nil)            ;; ひとつ前の盤面（ノード）に適用した手筋名
  (present-board nil)           ;; 現在の盤面を表す2次元配列
  (working-board nil)           ;; 関数[guess-game]で解答毎に更新するための盤面。
  (state nil)                   ;; [状態]::='start|'finished|'applied|'unsolved|'inconsistent ;
  (seen nil)                    ;; 既に訪れたことのあるノードなら[t]
  (dead-route nil)              ;; 全ての手筋を使っても解けない盤面に至るルートなら[t]
  (quiz-info nil)               ;; 盤面で適用できる手筋推定ゲーム用の情報。
  (quiz-list nil)               ;; [quiz-info]に登録された手筋解法情報の未使用番号のリスト。
  (quiz-list-backup nil)        ;; [quiz-list]のバックアップ用。一旦設定したら変更しない。
  (grouped-quiz-info nil)       ;; 盤面で適用できる手筋推定ゲーム用の情報。削除確定情報が同じものをまとめた情報。
  (grouped-quiz-list nil)       ;; [grouped-quiz-info]に登録された手筋解法情報の未使用番号のリスト。
  (grouped-quiz-list-backup nil);; [grouped-quiz-list]のバックアップ用。一旦設定したら変更しない。
  )

;;;
;;; 関数名と手筋名の対応リスト
;;; (assoc 'function-name (function-name-to-tesuji-name-list)) returns (function-name . 手筋名)
;;;
;;; (function-name-to-tesuji-name 'function-name) returns 手筋名
;;;
(defparameter *english-function-name-to-tesuji-name*
  (list
   '(do-fundamental                  . "fundamental")
   '(do-localization                 . "localization")
   '(do-n-tuples                     . "n-tuples")
   '(do-n-grid                       . "n-grid")
   '(do-almost-locked-set            . "Almost-Locked-Set")
   '(do-grid-based-almost-locked-set . "Grid-Based-Almost-Locked-Set")
   '(do-pattern-overlay-method       . "pattern-overlay-method")
   '(do-advanced-coloring            . "Advanced-Coloring")
   '(do-nice-loop                    . "Nice-Loop")
   '(do-trial-and-error              . "trial-and-error")
   )
  )

(defparameter *japanese-function-name-to-tesuji-name*
  (list
   '(do-fundamental                  . "基本手筋")
   '(do-localization                 . "ローカライゼーション")
   '(do-n-tuples                     . "n国同盟")
   '(do-n-grid                       . "nグリッド")
   '(do-almost-locked-set            . "Almost-Locked-Set")
   '(do-grid-based-almost-locked-set . "Grid-Based-Almost-Locked-Set")
   '(do-pattern-overlay-method       . "配置確定法")
   '(do-advanced-coloring            . "Advanced-Coloring")
   '(do-nice-loop                    . "Nice-Loop")
   '(do-trial-and-error              . "試行錯誤法")
   )
  )

;; [step-around]で使用するコマンド名のリスト。
(defparameter *step-around-menu-list*
  '(auto board change collection description dribble enter eval explore find goal guess help information
    level load lpr menu output pause quit read route save select store tesuji up version \>\>\> \$\$\$))

;; [make-menu-name-list]で作成したコマンド名と表示用コマンド名文字列のペア・リストのリストを保存する。
;; [menu-name]関数の第2引数のデフォルト値になる。
(defparameter *menu-name-pair-list* nil)

;; 関数[add-help], [add-methods-help]で指定するヘルプ項目名に漢字を使わないで済むように
;; ヘルプ項目名と言語設定による表示用手筋名を内部で自動変換するようにした。
;; ※ UTF-8に対応しておらず(文字列としては許すが)シンボル名に漢字を許さない処理系に対する配慮。
(defparameter *tesuji-help-name-to-function-name*
  (list
   '(fundamental                        . do-fundamental)
   '(localization                       . do-localization)
   '(n-tuples                           . do-n-tuples)
   '(n-grid                             . do-n-grid)
   '(almost-locked-set                  . do-almost-locked-set)
   '(pattern-overlay-method             . do-pattern-overlay-method)
   '(grid-based-almost-locked-set       . do-grid-based-almost-locked-set)
   '(advanced-coloring                  . do-advanced-coloring)
   '(nice-loop                          . do-nice-loop)
   ;;'(trial-and-error                  . do-trial-and-error)
   )
  )

(defparameter *tesuji-function-charenge-count*
  (list
   '(do-fundamental                        . 0)
   '(do-localization                       . 0)
   '(do-n-tuples                           . 0)
   '(do-n-grid                             . 0)
   '(do-almost-locked-set                  . 0)
   '(do-pattern-overlay-method             . 0)
   '(do-grid-based-almost-locked-set       . 0)
   '(do-advanced-coloring                  . 0)
   '(do-nice-loop                          . 0)
   )
  )

(defun tesuji-function-charenge-count (tesuji-function-name &optional (num 0 sw))
"手筋関数名に対して何問目のチャレンジかを記録・返答する関数。"
  (cond
    ((null sw)
     (cdr (assoc tesuji-function-name *tesuji-function-charenge-count*))
     )
    ((and (identity sw) (numberp num))
     (setf (cdr (assoc tesuji-function-name *tesuji-function-charenge-count*)) num)
     )
    ) ;; end cond
  )

(defun reset-tesuji-function-charenge-count ()
"[*tesuji-function-charenge-count*]の全てのペアリストの値をゼロにリセットする関数。"
  (dolist (p *tesuji-function-charenge-count* t)
    (setf (cdr (assoc (car p) *tesuji-function-charenge-count*)) 0)
    )
  )

;;(defvar *function-name-to-tesuji-name* *english-function-name-to-tesuji-name*)
(defvar *function-name-to-tesuji-name* *japanese-function-name-to-tesuji-name*)

(defparameter *block-size* 3)                           ;; 仮の初期値。変更は関数block-sizeで。
(defparameter *board-size* 9)                           ;; 仮の初期値。変更は関数board-sizeで。
(defparameter *np-digit* '(1 2 3 4 5 6 7 8 9))          ;; 仮の初期値。変更は関数block-sizeが行う。
(defparameter *explanation-level* 0)                    ;; 解説レベル。
(defparameter *need-multiple-answer* t)                 ;; 2個目以降の解を探索するかどうかを設定する。
(defparameter *check-backtrack-point* nil)              ;; バックトラックが発生した時点の情報を出力する。
(defparameter *debug-level* 0)                          ;; デバッグ情報の出力レベル。
(defparameter *insert-pause* nil)                       ;; ボードを n回出力するごとに一時停止する。
(defparameter *print-mini* nil)                         ;; ボードを小さいサイズで出力する。
(defparameter *print-chunk* t)                          ;; 解を数字列形式「でも」表示するかを設定する。
(defparameter *print-check* nil)                        ;; 手筋を解説するボードを出力する。
(defparameter *auto-trim-level* 100)                    ;; 未確定セル数が、この率未満ならば刈り込む。
(defparameter *chain-trim* t)                           ;; 再帰的(連鎖的)な枝刈りを行うかを設定する。
(defparameter *current-preset-level* nil)               ;; 動作制御関数のプリセット値を記録しておく。
(defparameter *trim-every-time* t)                      ;; 候補が確定する都度その場で刈り込むか設定する。
(defparameter *n-grid-limit* nil)                       ;; グリッド解析の上限を設定する。[nil]は制限なし。
(defparameter *tuples-limit* nil)                       ;; n国同盟の上限を設定する。[nil]は制限なし。
(defparameter *min-nice-length* 3)                      ;; Nice Loopとして許可する連鎖の最短長さ。[3]以上。
(defparameter *max-nice-length* nil)                    ;; 許可する連鎖の最大長さ。[nil]は無制限。
(defparameter *max-nice-loops* nil)                     ;; Nice Loopで採用する最大経路数。[nil]は無制限。
(defparameter *print-with-symbol-letter* t)             ;; Nice Loop経路表示にラベル記号も表示するか。
(defparameter *capital-address* t)                      ;; セル・アドレスを大文字で表示するか。[t]->[RxCy]。
(defparameter *pencil-mark* t)                          ;; 候補数字を「ペンシル・マーク」形式で表示する。
(defparameter *plot-level* nil)                         ;; プロット時の情報量を指定。関数[plot]で定義。
(defparameter *difficulty-obvious* 1)                   ;; 「残り物」に対する「難易度」を[1]とする(基準)。
(defparameter *difficulty-fundamental* 2)               ;; 置く手筋。
(defparameter *difficulty-trim* 6)                      ;; 確定値を元に候補の全刈り込み。
(defparameter *difficulty-only-one* 5)                  ;; 単独候補(行・列・ブロック内で唯一の候補)。
;;(defparameter *difficulty-cell-unique* 6)             ;; セル・ユニーク(グループ内で唯一可能な確定値)。
(defparameter *difficulty-localization* 4)              ;; ローカライゼーション。
(defparameter *difficulty-tuples-naked* 2)              ;; naked型2国同盟。組が増えるごとに[+2]。
(defparameter *difficulty-tuples-hidden* 4)             ;; hidden型2国同盟。組が増えるごとに[x2]。
(defparameter *difficulty-n-grid* 7)                    ;; グリッド数が増えるごとに[x2]
(defparameter *difficulty-pattern-overlay-method* 10)   ;; 配置確定法(Pattern Overlay Method)。
(defparameter *difficulty-nice-loop* 9)                 ;; Nice Loop。連鎖が増えるごとに[+2]。
(defparameter *difficulty-advanced-coloring* 8)         ;; Advanced Coloring(AC)の基準難易度。
(defparameter *difficulty-trial-and-error* 5)           ;; 試行錯誤(仮置き)法。
(defparameter *difficulty-ALS* 7)                       ;; Almost Locked Setの基準難易度。
(defparameter *difficulty-GB-ALS* 6)                    ;; Grid-Based Almost Locked Setの基準難易度。
(defparameter *difficulty-mark* 0)                      ;; プロット図に目印を出力する基準用。
(defparameter *scale* 1)                                ;; プロット図の1目盛の値。
(defparameter *method-print-width* 30)                  ;; プロット図に手筋名称を出力する際の出力幅。右詰。
(defparameter *think-depth* nil)                        ;; 手筋の「読み」を許可するかどうかを設定する。
(defparameter *easy-method-first* nil)                  ;; 発見・適用が「易しい」手筋を常に優先する。
(defparameter *output-nice-graph* nil)                  ;; 盤面の全リンク情報を[GraphViz]データとして出力。
(defparameter *advanced-ratio* 1/10)                    ;; ACを実行する2値セル/未確定セルの最低比率。
(defparameter *permit-cheat* t)                         ;; 試行錯誤を行う際に正解候補の選択を許す。
(defparameter *print-eliminatable* t)                   ;; ACで削除可能な候補数字を彩色して表示するか。
(defparameter *ALS-show-all* nil)                       ;; ALSの全手筋表示なら[t]、効率的手筋のみなら[nil]。
(defparameter *ALS-show-stat* nil)                      ;; ALSに関する統計データ表示の有無を設定する。
(defparameter *ALS-check-limit* nil)                    ;; ALSの組み合わせチェックの上限値。[nil]は上限なし。
(defparameter *GB-ALS-show-all* nil)                    ;; GB-ALSの全手筋表示なら[t],効率的手筋のみは[nil]。
(defparameter *show-color-board* nil)                   ;; 彩色した解説ボードを表示するか否かを設定する。
(defparameter *normal-shaft-string* "--")               ;; [print-way-to-goal]で出力する矢印のシャフト部分。
(defparameter *dead-end-shaft-string* "==")             ;; 同上。ただし[Dead End]ルート用。
(defparameter *continuous-nice* "連続的Nice Loop")      ;; Continuous Nice Loopの日本語表記。
(defparameter *discontinuous-nice* "非連続Nice Loop")   ;; Discontinuous Nice Loopの日本語表記。
(defparameter *paps* 'not-checked-yet)                  ;; papsコマンドの存在をチェック済みかを記録する。
(defparameter *lpr* "lpr")                              ;; lprコマンドのコマンド名を定義する。
(defparameter *need-working-board*                      ;; 関数[guess-game]で問題を解くたびに盤面更新が
  '(do-n-tuples do-n-grid))                             ;; 必要な関数のリスト。
(defparameter *update-board-every-game*                 ;; 関数[guess-game]で問題を解くたびに盤面更新を
  '(do-fundamental do-nice-loop))                       ;; 行う関数のリスト(任意)。
(defparameter *grading-level* 1/100)                    ;; 関数[guess-game]の合格ライン。
(defparameter *ALS-rule-1* "Almost Locked Set rule 1")  ;; almost-locked-set-rule-1
(defparameter *ALS-rule-2* "Almost Locked Set rule 2")  ;; almost-locked-set-rule-2
(defvar *debug-point* nil)                              ;; デバッグ出力用目印文字列を登録する。
(defvar *debug-point-save* nil)                         ;; *debug-point*の一時的な保存場所。
(defvar *selected-user-level* nil)                      ;; '(novice-level ... machine-level)
(defvar *method-count* 0)                               ;; 各手筋の合計実行回数。
(defvar *score* 0)                                      ;; 手筋ごとに設定した「難易度」の合計。
(defvar *max-score* 0)                                  ;; 「難易度」の最大値を記録する。
(defvar *exec-count* 0)                                 ;; 試行錯誤関数の実行回数。
(defvar *max-depth* 0)                                  ;; 試行錯誤関数の再帰呼び出し最大深さを記録する。
(defvar *max-nice-depth* 0)                             ;; Nice Loop関数の再帰呼び出し最大深さを記録する。
(defvar *nice-count* 0)                                 ;; Nice Loop関数の実行回数。
(defvar *nice-loop-count* 0)                            ;; Nice Loop関数内のループ・カウンタ。
(defvar *letter-label-counter* 0)                       ;; [*letter-labels*]用のカウンタ。
(defvar *output-new-page* nil)
(defvar *help-item* nil)
(defvar *help-methods* nil)
(defvar *method-applied* nil)
(defvar *depth* 0)
(defvar *nice-depth* 0)
(defvar *board-print-counter* 0)
(defvar *answer* nil)
(defvar *np-environment* nil)
(defvar *snap-shot* nil)
(defvar *LinkMap-counter* 0)
(defvar *parity-color-counter* 0)
(defvar *elimination-list* nil)
(defvar *applied-logics* 0)
(defvar *evil-boards* nil)
(defvar *cheat-board* nil)
(defvar *last-color-type* nil)
;;;     以下は関数[examin]関係の大域変数。
(defvar *default-node-data-fname-prefix* "node-data-") ;; ナンプレの解法過程データを保存するファイル名の接頭辞。
(defvar *default-games-fname-prefix* "sudoku-games-")  ;; ナンプレの盤面データを保存するファイル名の接頭辞。
(defvar *root-node* nil)           ;; ルート・ノードを保持している大域変数。
(defvar *game-node-number* 0)      ;; ノードに一意な番号を割り当てるためのカウンタ。
;;(defvar *sudoku-name-number* -1)   ;; 保存する盤面データに一意な名前を割り当てるためのカウンタ。
(defvar *game-node-list* nil)      ;; ノード番号/ラベルからノード本体を検索する速度を高速化するためのリスト。
(defvar *game-label-list* nil)     ;; ノード番号にユーザが任意で設定するラベルを保持するリスト。
(defvar *allow-explore* nil)       ;; 関数[step-around]のメニューから[find-all-logical-path]を使えるようにする。
(defvar *long-explanation* t)      ;; L)oad コマンドの詳しい説明も表示する。
(defvar *normal-explanation* t)    ;; L)oad コマンドの通常説明を表示する。
(defvar *minimum-explanation* t)   ;; L)oad コマンドの最小限の説明を表示する。
(defvar *no-explanation* nil)      ;; L)oad コマンドの説明を表示しない。
(defvar *show-used-tesuji* nil)    ;; 実際に使用されている手筋を表示する際に先頭に"*"を表示する。
(defvar *auto-save-node* nil)      ;; [find-all-logical-path]で途中経過を自動保存するか設定する。
(defvar *dribbling* nil)           ;; dribbleセッション中なら[t]、そうでないなら[nil]。
(defvar *can-dribble*
  #+clisp (list "CLISP")          ;; SBCLではエラーになる。
  #-clisp nil
  )
(defvar *allow-external-command* t) ;; 外部コマンドの実行を許可するか。処理系依存。現在clispのみサポート。
(defvar *can-use-external-less* 
  #+clisp (list "CLISP")           ;; SBCLでは"less","more"はエラーになる("cat","ls"などはOK)。
  #-clisp nil
  )
(defvar *use-external-less*         ;; 80文字×25行分以上の文字数であれば外部コマンドの[less]を使って表示する。
  (* 80 25))
(defvar *inconsistent-case* nil)    ;; 手筋適用条件を満たしているのに盤面に矛盾を生じたケースを収集する。
(defvar *ignore-show-help* nil)     ;; [t]なら(show-help nil)を無効にする。
(defvar *secret-command-for-debug* nil)
                                    ;; 矛盾発生時のデータをメニューから保存できるようにする。
(defvar *auto-save-minutes* 5)      ;; [*auto-save-node*]が[nil]でないとき[find-all-logical-path]実行中に
                                    ;;設定時間(分単位) ごとに途中経過をファイルに自動保存する。
(defvar *read-multiple-string* nil) ;; (read-multiple-string)の2番目以降の値を保存する。
(defvar *read-multiple-symbol* nil) ;; (read-multiple-symbol)の2番目以降の値を保存する。
(defvar *original-read-string-list* nil);; (read-multiple-symbol)のオリジナルの入力文字列。
(defvar *multi-position-function*   ;; 異なる理由で同じセルに同じ削除・確定情報が発生する可能性がある関数のリスト。
  '(do-fundamental))
;; ベンチマーク用データの保存場所。
(defvar top95 (make-array 96 :initial-element nil))

;; Escapeキーのキーコード登録。
(defparameter ESC #\^[)

;; Tabキーのキーコード登録。
(defparameter *Tab* #\Tab)

;; GraphVizで使用する辺の色の既定値。リスト順に使用する。順序変更,追加,削除自由。
;; 色分けに使う色数はページ当たり8色(8区分)程度までが限界。3から5色程度がお勧め。
;; 色名は http://www.graphviz.org/doc/info/colors.html による。
;;(defparameter *edge-colors* '(deeppink2 green blue orangered navy darkorange purple brown))
(defparameter *edge-colors* '(deeppink2 green blue))

;; ------------------------------------------------
;; Advanced Coloringにおける盤面出力で使用する画面への色出力の初期値を定義する。
;; 再設定は (color-mode [number])。引数なしで (color-mode) とすると現在の値を返す。
;;
;; 2 = 彩色対象候補数字をカラーで出力。
;; 1 = 彩色対象候補数字をカラーの短縮色名で出力。
;; 0 = 彩色対象候補数字を短縮色名で出力(完全モノクロ)。
(defvar *color-mode-level* 0)

;; 彩色方法として背景色を選択する場合は「'xterm-background-color」を、
;; 色付き文字を選択する場合は「'xterm-text-color」を定義する。
;; 実行時に定義を変更する場合は関数「color-type」で設定する。
;;+(defvar *color-type* 'xterm-background-color)
(defvar *color-type* 'xterm-text-color)
;;+(defvar *color-type* 'ansi-background-color)
;;+(defvar *color-type* 'ansi-text-color)

;; Advanced Coloringでparityとして使用する色の定義。3色+デバッグ用1色の合計4色を使用する。
;; parityとして使用する2色を追加するための関数を用意している。3段階の追加方法を用意している。
;;
;; (1) 最も簡単な方法 = 2種類のパリティ色を予め用意されている色から選ぶ方法。
;;       (set-parity-1)
;;     とすると選択できる色名の一覧が表示されるので好みの色を選び、
;;       (set-parity-1 'green)
;;     のように実行する。もうひとつのパリティ色の設定方法も同様で
;;       (set-parity-2 'blue)
;;     のように実行する。
;;
;; (2) 解説盤面に表示される1文字の短縮色名も設定したい場合。
;;       (set-parity-color-1 46 "G")
;;     のように実行する。第１引数の数値[46]が色種類を示すカラー・コード。第２引数の["G"]が
;;     解説盤面で使用される1文字の短縮色名。それぞれのカラー・コードに対して固有の色が割り当てられている。
;;     具体的な色の割り当ては
;;      (print-color-sample)
;;     と実行すると実際の色見本が表示されるので好みで決める。もうひとつのパリティ色の設定方法も同様で
;;       (set-parity-color-2 27 "B")
;;     のように設定する。
;;
;; (3) プログラム内部で使用するパリティ色の名前も指定したい場合(プログラマ向け)。
;;       (set-parity-color [num] [color-code] [short-name] &optional ([color-name] nil))
;;         [num]        ::= [*parity-colors*]の[num]番目の要素として定義する。
;;         [color-code] ::= 使用したい色のコード番号。(print-color-sample)を実行すると参照できる。
;;         [short-name] ::= 色名を表す1文字の名前。Advanced Coloringの解説盤面内で使用する。
;;                          文字列を指定した場合は先頭文字が指定されたものとして扱う。
;;         [color-name] ::= プログラム内部で使用するパリティ色の名前を設定する。
;;                          指定しなかった場合の既定値は '*color-1* と '*color-2*。
;;

;; それぞれの「色」に対して設定するカラー・コード値の定義。色味は好みで変更できる。
;; xcolorの場合、最大256色定義できる。https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
;; (print-color-sample)と上記の設定方法を参照。
(defparameter *xcolor-black*    232)
(defparameter *xcolor-red*      124)
(defparameter *xcolor-green*     28)
(defparameter *xcolor-yellow*   226)
(defparameter *xcolor-blue*      27)
(defparameter *xcolor-magenta*   93)
(defparameter *xcolor-cyan*      69)
(defparameter *xcolor-gray*     239)

;; ansiカラーの場合、最大8色まで。
(defparameter *ansi-black*      0)
(defparameter *ansi-red*        1)
(defparameter *ansi-green*      2)
(defparameter *ansi-yellow*     3)
(defparameter *ansi-blue*       4)
(defparameter *ansi-magenta*    5)
(defparameter *ansi-cyan*       6)
(defparameter *ansi-white*      7)

;; 削除対象の候補数字を彩色する色の定義。[*parity-colors*]で使用する色を避けること。
(defparameter *elimination-color* 1) ;; *ansi-red*と同じ。

;; 複数のパリティ・カラーが重複して割り当てられた場合に置き換えられる「矛盾色」の定義。
;; [*parity-colors*]で使用する色を避けること。デバッグ用。表示されたらバグ。
(defparameter *conflict-color* 5) ;; *ansi-magenta*と同じ。

;;(defparameter *xterm-parity-color-list*
(defparameter *xterm-basic-color-list*
  '((red        .       *xcolor-red*) ;; 削除対象候補用。パリティ色に使う場合は要注意。
    (green      .       *xcolor-green*)
    (blue       .       *xcolor-blue*)
    (cyan       .       *xcolor-cyan*)
    (magenta    .       *xcolor-magenta*)
    (yellow     .       *xcolor-yellow*)
    (black      .       *xcolor-black*)
    (gray       .       *xcolor-gray*)
    (*elimination-color* . *elimination-color*)
    (*conflict-color*    . *conflict-color*)
    )
  )

(defparameter *xterm-parity-color-list*
  (append *xterm-basic-color-list*
          '( (*elimination-color* . *elimination-color*)
            (*conflict-color*    . *conflict-color*) ) )
  )

;;(defparameter *ansi-parity-color-list*
(defparameter *ansi-basic-color-list*
  '((red       .       *ansi-red*) ;; 削除対象候補用。パリティ色に使う場合は要注意。
    (green     .       *ansi-green*)
    (blue      .       *ansi-blue*)
    (cyan      .       *ansi-cyan*)
    (magenta   .       *ansi-magenta*)
    (yellow    .       *ansi-yellow*)
    (white     .       *ansi-white*)
    (black     .       *ansi-black*)
    (*elimination-color* . *elimination-color*)
    (*conflict-color*    . *conflict-color*)
    )
  )

(defparameter *ansi-parity-color-list*
  (append *ansi-basic-color-list*
          '((*elimination-color* . *elimination-color*)
            (*conflict-color*    . *conflict-color*) ) )
  )

(defvar *parity-color-list* *xterm-parity-color-list*)
;;(defparameter *parity-color-list* *ansi-parity-color-list*)

(defvar *user-authorized-color-list* (mapcar #'first *parity-color-list*))
(defvar *internal-color-list* (mapcar #'rest *parity-color-list*))
(defvar *system-authorized-color-list* '(*elimination-color* *conflict-color*))
(defvar *authorized-color-list* (append *user-authorized-color-list* *system-authorized-color-list*))

;; [*parity-colors*]に登録された各色の1文字での短縮表記を定義する。
(defparameter *xterm-short-colors*
  '((*xcolor-red*              .       #\R)
    (*xcolor-green*            .       #\G)
    (*xcolor-blue*             .       #\B)
    (*xcolor-cyan*             .       #\C)
    (*xcolor-magenta*          .       #\M)
    (*xcolor-yellow*           .       #\Y)
    (*xcolor-black*            .       #\K)
    (*xcolor-gray*             .       #\G)
    (*elimination-color*       .       #\X)
    (*conflict-color*          .       #\?)
    )
  )

(defparameter *ansi-short-colors*
  '((*ansi-red*                .       #\R)
    (*ansi-green*              .       #\G)
    (*ansi-blue*               .       #\B)
    (*ansi-skyblue*            .       #\S)
    (*ansi-purple*             .       #\P)
    (*ansi-yellow*             .       #\Y)
    (*ansi-white*              .       #\W)
    (*ansi-black*              .       #\K)
    (*elimination-color*       .       #\X)
    (*conflict-color*          .       #\?)
    )
  )
;;
(defvar *short-colors* *xterm-short-colors*)
;;(defparameter *short-colors* *ansi-short-colors*)

;; 彩色対象の候補数字に使用する色。上記の一覧から2つ選ぶ。
;; プログラム中で使用する色名は「*parity-colors*」を通して間接的に参照する。
;; プログラム中では色名を直接参照していない。
(defparameter *xterm-original-parity-colors* '(*xcolor-green* *xcolor-blue*))
(defparameter *xterm-parity-colors* *xterm-original-parity-colors*)

(defparameter *ansi-original-parity-colors* '(*ansi-green* *ansi-blue*))
(defparameter *ansi-parity-colors* *ansi-original-parity-colors*)

(defvar *parity-colors* *xterm-parity-colors*)
;;(defvar *parity-colors* *ansi-parity-colors*)

;; ------------------------------------------------

(defparameter *not-equal-mark* "<>")            ;;Nice Loopでの削除可能候補表示で使用する不等号マーク。
;;(defparameter *not-equal-mark* "≠ ")                ;;Nice Loopでの削除可能候補表示で使用する不等号マーク。

(defparameter *equal-mark* "=")                         ;;Nice Loopでの削除可能候補表示で使用する等号マーク。
;;(defparameter *equal-mark* " = ")                     ;;Nice Loopでの削除可能候補表示で使用する等号マーク。

;;; Nice Loopの経路表示で使用するラベル記号の定義。[*letter-labels*]で定義された順に使用する。
;;; もし末尾まで使い切るとリスト先頭の文字に戻る。
(defparameter *capital-letter-labels*
  '("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M"
    "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"))

(defparameter *small-letter-labels*
  '("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m"
    "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"))

(defparameter *letter-labels* (append *capital-letter-labels* *small-letter-labels*))

(defparameter  *empty-char* "")
(defparameter  *at-mark* "@")
(defparameter  *sharp-mark* "#")
(defparameter  *dollar-mark* "$")
(defparameter  *period-mark* ".")
(defparameter  *space* " ")     ;;盤面中の空白文字。
(defparameter *spc* " ")        ;;盤面中の空数字の初期値。(space-char-is ch)で変更。
;;(defparameter *spc* ".")      ;;盤面中の空数字の初期値。半角ピリオド。
;;(defparameter *spc* "・")     ;;盤面中の空数字の初期値。半角中黒。

(defparameter *white-space* '(#\Space #\Tab #\Linefeed))
;;
;; Sample data
;;
(defparameter sample-board-0 #2a ;; No data. 印刷すると手書き用ボードに使える。
  ((0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0)))
;; [14]> (print-normal sample-board-0)
;; #=======================================================================#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #=======================#=======================#=======================#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #=======================#=======================#=======================#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
;; #=======================================================================#


(defparameter sample-board-1 #2a
  ((0 6 0 0 8 0 0 7 4)
   (7 3 0 0 0 9 0 1 2)
   (0 0 1 0 0 0 6 0 0)
   (0 0 0 3 0 5 0 2 0)
   (4 0 0 0 9 0 0 0 3)
   (0 8 0 6 0 2 0 0 0)
   (0 0 4 0 0 0 1 0 0)
   (3 5 0 7 0 0 0 6 8)
   (6 1 0 0 5 0 0 9 0)))

(defparameter sample-board-1-result #2a
  ((9 6 5 2 8 1 3 7 4)  ;; sample-board-1 の正解。
   (7 3 8 4 6 9 5 1 2)
   (2 4 1 5 3 7 6 8 9)
   (1 9 7 3 4 5 8 2 6)
   (4 2 6 1 9 8 7 5 3)
   (5 8 3 6 7 2 9 4 1)
   (8 7 4 9 2 6 1 3 5)
   (3 5 9 7 1 4 2 6 8)
   (6 1 2 8 5 3 4 9 7)))

(defparameter sample-board-2 #2a
  ((0 0 0 3 0 0 0 0 0)
   (0 0 1 4 6 0 0 0 0)
   (0 9 0 0 0 0 8 0 0)
   (2 5 0 0 0 0 0 0 0)
   (0 8 0 0 0 0 0 4 0)
   (0 0 0 0 0 0 0 6 3)
   (0 0 4 0 0 0 0 7 0)
   (0 0 0 0 1 8 2 0 0)
   (0 0 0 0 0 2 0 0 0)))

(defparameter sample-board-3 #2a ;Hard.
  ((0 0 0 3 0 0 0 0 0)
   (0 0 3 4 6 0 0 0 0)
   (0 8 0 0 0 0 5 0 0)
   (9 2 0 0 0 0 0 0 0)
   (0 5 0 0 0 0 0 4 0)
   (0 0 0 0 0 0 0 7 3)
   (0 0 4 0 0 0 0 2 0)
   (0 0 0 0 2 5 6 0 0)
   (0 0 0 0 0 9 0 0 0)))

(defparameter sample-board-4 #2a
  ((0 0 0 0 0 3 4 0 0)
   (0 8 0 0 0 0 0 7 0)
   (0 0 5 0 0 8 0 0 9)
   (0 0 0 4 0 0 6 0 7)
   (0 0 0 0 0 0 0 0 0)
   (5 0 4 0 0 1 0 0 0)
   (6 0 0 2 0 0 3 0 0)
   (0 3 0 0 0 0 0 1 0)
   (0 0 9 7 0 0 0 0 0)))

(defparameter sample-board-5 #2a
  ((0 0 0 0 3 0 0 0 0)
   (0 3 7 0 0 0 1 4 0)
   (0 8 0 9 0 1 0 7 0)
   (0 0 5 6 0 8 9 0 0)
   (9 0 0 0 7 0 0 0 8)
   (0 0 2 1 0 3 4 0 0)
   (0 2 0 4 0 7 0 6 0)
   (0 5 8 0 0 0 3 1 0)
   (0 0 0 0 8 0 0 0 0)))

(defparameter sample-board-6 #2a ;; Hard
  ((0 0 0 0 8 3 9 0 0)
   (1 0 0 0 0 0 0 3 0)
   (0 0 4 0 0 0 0 7 0)
   (0 4 2 0 3 0 0 0 0)
   (6 0 0 0 0 0 0 0 4)
   (0 0 0 0 7 0 0 1 0)
   (0 2 0 0 0 0 0 0 0)
   (0 8 0 0 0 9 2 0 0)
   (0 0 0 2 5 0 0 0 6)))

(defparameter sample-board-7 #2a ;; 解が2個存在
  ((0 5 4 2 3 0 0 0 0)
   (0 9 8 7 4 0 0 5 2)
   (0 0 0 0 0 0 0 7 8)
   (0 0 0 0 0 0 0 2 4)
   (4 6 0 0 0 0 0 1 7)
   (5 8 0 0 0 0 0 0 0)
   (8 3 0 0 0 0 0 0 0)
   (1 2 0 0 8 7 6 3 0)
   (0 0 0 0 2 3 7 8 0)))

(defparameter sample-board-8 #2a
  ((0 0 0 0 5 0 0 0 0)
   (0 0 1 0 3 0 7 0 0)
   (0 6 5 0 0 0 9 2 0)
   (0 0 0 2 0 0 0 0 0)
   (3 9 0 0 4 0 0 5 1)
   (0 0 0 0 0 3 0 0 0)
   (0 5 4 0 0 0 8 6 0)
   (0 0 6 0 7 0 1 0 0)
   (0 0 0 0 9 0 0 0 0)))

(defparameter sample-board-9 #2a
  ((0 0 0 0 0 0 0 0 0)
   (0 4 0 3 0 9 0 1 0)
   (0 0 2 0 6 0 8 0 0)
   (0 3 0 0 0 6 0 4 0)
   (0 0 7 0 0 0 2 0 0)
   (0 1 0 9 0 0 0 3 0)
   (0 0 5 0 2 0 6 0 0)
   (0 2 0 1 0 3 0 5 0)
   (0 0 0 0 0 0 0 0 0)))

(defparameter sample-board-10 #2a        ;; AIEscagot
  ((1 0 0 0 0 7 0 9 0)
   (0 3 0 0 2 0 0 0 8)
   (0 0 9 6 0 0 5 0 0)
   (0 0 5 3 0 0 9 0 0)
   (0 1 0 0 8 0 0 0 2)
   (6 0 0 0 0 4 0 0 0)
   (3 0 0 0 0 0 0 1 0)
   (0 4 0 0 0 0 0 0 7)
   (0 0 7 0 0 0 3 0 0)))

(defparameter sample-board-10-result #2a ;; AIEscagotの解
  ((1 6 2 8 5 7 4 9 3)
   (5 3 4 1 2 9 6 7 8)
   (7 8 9 6 4 3 5 2 1)
   (4 7 5 3 1 2 9 8 6)
   (9 1 3 5 8 6 7 4 2)
   (6 2 8 7 9 4 1 3 5)
   (3 5 6 4 7 8 2 1 9)
   (2 4 1 9 3 5 8 6 7)
   (8 9 7 2 6 1 3 5 4)))

(defparameter sample-board-11 #2a        ;; 16x16の問題。
  ((8 0 1 0 6 0 0 3 0 0 0 0 0 10 16 0)
   (0 0 0 0 12 0 0 0 2 16 0 4 0 0 0 3)
   (0 14 0 13 15 5 0 0 0 0 0 9 0 0 0 0)
   (7 0 6 0 0 10 11 0 0 0 0 0 5 0 0 0)
   (0 10 0 0 0 0 1 12 0 0 0 11 0 2 0 7)
   (0 0 11 0 0 0 4 0 0 15 0 0 6 0 13 0)
   (0 0 0 0 9 0 0 8 0 0 1 0 12 3 0 0)
   (16 0 0 8 0 0 0 0 0 6 5 0 0 0 0 4)
   (12 2 0 0 0 13 0 0 3 0 0 0 0 0 14 0)
   (0 0 4 15 10 0 0 0 0 0 6 0 0 1 8 0)
   (0 13 0 14 5 0 7 0 0 10 0 0 0 0 0 16)
   (5 0 0 0 0 3 0 16 0 12 8 0 9 11 0 0)
   (0 6 3 0 0 7 0 2 0 0 14 0 0 0 0 12)
   (0 0 10 16 0 14 13 0 1 0 0 0 0 8 15 0)
   (0 5 0 4 0 0 0 0 13 0 11 2 0 0 0 0)
   (0 0 9 0 0 0 15 0 0 4 0 7 11 0 0 1)))

;; Inkala  see http://www.efamol.com/efamol-news/worlds-hardest-sudoku.asp
(defparameter sample-board-12 #2a
  ((0 0 5 3 0 0 0 0 0)
   (8 0 0 0 0 0 0 2 0)
   (0 7 0 0 1 0 5 0 0)
   (4 0 0 0 0 5 3 0 0)
   (0 1 0 0 7 0 0 0 6)
   (0 0 3 2 0 0 0 8 0)
   (0 6 0 5 0 0 0 0 9)
   (0 0 4 0 0 0 0 3 0)
   (0 0 0 0 0 9 7 0 0)))

(defparameter Inkala sample-board-12)

;;; tuplesチェック用ボード。hidden tuples, naked tuplesを含む。例えば
;;; 4行1列、4行2列、4行3列の各セルは、この3カ所で(4,5,7)の3種の候補。
(defparameter tuples-sample  #2a
  ((5 4 (1 6 7 8) 2 (1 7 9) (8 9) (1 9) (1 6) 3)
   ((3 8) 2 (1 6 8) (1 3 5 8 9) (1 3 5 9) (3 5 8 9) (1 4 5 9) (1 4 5 6) 7)
   ((3 7) (1 3 7) 9 4 (1 3 5 7) 6 8 2 (1 5))
   (1 6 2 7 8 (3 4 5) (3 4 5) 9 (4 5))
   (4 9 3 (1 5) (1 5) 2 7 8 6)
   ((7 8) 5 (7 8) (1 3 9) 6 (3 4 9) (1 3 4) (1 4) 2)
   (9 (3 8) 4 (3 5 8) 2 1 6 7 (5 8))
   (2 (1 7 8) (1 5 7 8) 6 (4 5 9) (4 5 8 9) (1 4 5) 3 (1 4 5 8))
           (6 (1 3 8) (1 5 8) (3 5 8) (3 4 5) 7 2 (1 4 5) 9)))

(defparameter from-mixi-lm #2a   ;from mixi.
  ((0 0 4 0 0 2 0 0 9)
   (3 0 0 0 0 1 0 0 0)
   (0 7 0 9 0 0 4 0 5)
   (1 0 8 0 0 3 0 9 0)
   (0 0 0 0 0 0 0 0 0)
   (0 9 0 2 0 0 5 0 3)
   (7 0 3 0 0 4 0 8 0)
   (0 0 0 7 0 0 0 0 2)
   (9 0 0 8 0 0 3 0 0)))

;;; Nice Loopテスト用のサンプル・データ。(see http://www.sudoku.com/boards/viewtopic.php?t=2143)
(defparameter nice-01 #2a
  (((5 6) (5 6) 2 (3 8) 9 (3 4 8) 1 (3 4 8) 7)
   ((1 7 9) 3 8 6 (2 4 5 7) (1 2) (2 4 5) (5 9) (2 5 9))
   (4 (1 7 9) (1 7) (1 2 3 5 7 8) (2 5 7 8) (1 2 3 8) (2 5 6 8) (3 5 6 8 9) (2 3 5 6 8 9))
   ((1 2 3 6 7) (1 2 6 7 8) (1 3 4 7) (3 9) (2 6 7 8) 5 (2 4 6 8) (1 6 7 8 9) (1 2 6 8 9))
   ((2 5 6 7) (2 4 5 6 7 8) 9 (2 7 8) 1 (2 6 8) 3 (4 5 6 7 8) (2 5 6 8))
   ((1 2 3 5 6 7) (1 2 5 6 7 8) (1 3 5 7) 4 (2 6 7 8) (3 9) (2 5 6 8) (1 5 6 7 8 9) (1 2 5 6 8 9))
   ((1 2 3 5 7 9) (1 2 5 7 9) (1 3 5 7) (1 2 5 8 9) (2 5 6 8) (1 2 6 8 9) (6 8) (3 6 8) 4)
   ((1 3 5) (1 5) (1 3 4 5) (1 5 8) (4 5 6 8) 7 9 2 (3 6 8))
   (8 (2 4 9) 6 (2 9) 3 (2 4 9) 7 (1 5) (1 5))))

;;; -[r4c2]=1=[r4c6]=6=[r8c6]=2=[r8c1]=1=[r6c1]-1-[r4c2]= 
;;; => r4c6<>3, r8c6<>3, r8c1<>8 
(defparameter nice-02 #2a
  ((7 (5 8) 1 2 3 9 6 4 (5 8))
   (6 (3 8) 2 1 4 5 (3 8 9) (8 9) 7)
   ((5 3) 4 9 8 6 7 (2 3) 1 (2 5))
   (4 (1 2 3) (3 8) (3 6 9) 5 (1 2 6) (2 8 9) 7 (2 8 9))
   (9 (2 3 5) (3 5 7) (3 7) 8 (3 4) (2 4) 6 1)
   ((1 8) 6 (7 8) (7 9) 2 (1 4) (4 8 9) 5 3)
   ((3 5) 9 (3 5 6) (3 6) 1 8 7 2 4)
   ((1 2 8) (1 3) (3 6 8) 4 7 (2 3 6) 5 (3 8 9) (8 9))
   ((2 8) 7 4 5 9 (2 3) 1 (3 8) 6)) )

;;; -[r1c7]-9-[r3c9]-1-[r3c3]-3-[r4c3]-7-[r4c5]-4-[r6c5]-7-[r6c7]-4-[r7c7]-2-[r1c7]- 
;;; => r4c1<>7, r9c7<>2, r9c7<>4, and r4c9<>7 
(defparameter nice-03 #2a
  ((5 6 (2 9) 7 3 1 (2 9) 4 8)
   ((2 4 7) (2 4 8) (1 7) 5 9 (4 8) 6 3 (1 2))
   ((3 4 9) (3 4 8) (1 3) (4 8) 6 2 5 7 (1 9))
   ((3 6 7) 9 (3 7) 2 (4 7) 5 1 8 (4 6 7))
   ((2 7) (2 5) 4 (6 8) 1 (6 8) 3 (5 9) (5 7 9))
   ((1 6) (1 5) 8 3 (4 7) 9 (4 7) 2 (5 6))
   ((1 2 3 4) 7 6 9 8 (3 4) (2 4) (1 5) (2 4 5))
   ((1 3 4 9) (1 3 4) 5 (4 6) 2 (3 4 6 7) 8 (1 9) (4 7 9))
   (8 (2 4) (2 9) 1 5 (4 7) (2 4 7 9) 6 3) ))

;;; [r9c6]=8=[r9c7]=5=[r8c8]-5-[r3c8]=5=[r3c5]=8=[r3c2]-8-[r1c3]=8=[r8c3]-8-[r8c6]=8=[r9c6]
;;;  => r9c6=8
(defparameter nice-04 #2a
  (((2 4 7) 5 (2 8) (4 7 9) (4 7 8 9) 1 6 (3 7 9) (3 7 8 9))
   (3 (1 4 7) 6 (4 7 9) (4 5 7 8 9) 2 (5 7 8) (1 7 9) (5 7 8 9))
   ((1 7) (1 7 8) 9 3 (5 7 8) 6 2 (1 5 7) 4)
   ((7 9) 6 4 5 3 (7 9) 1 8 2)
   ((1 2 9) (1 2 3 9) (2 3) 8 6 4 (5 7) (3 5 7 9) (3 5 9))
   (8 (3 7 9) 5 1 2 (7 9) 4 6 (3 9))
   (6 (2 4 8) 1 (4 7 9) (4 7 9) 5 3 (2 7) (7 8))
   ((2 4 5) (2 3 4 8) (2 3 8) 6 (4 7) (3 8) 9 (2 5 7) 1)
   ((5 9) (3 9) 7 2 1 (3 8) (5 8) 4 6) ))

;;; [r7c2]-1-[r2c2]=1=[r2c7]=2=[r3c9]-2-[r3c6]-4-[r7c6]-1-[r7c2] => r7c2<>1
(defparameter nice-05 #2a
  (((3 9) 2 (3 9) 6 1 8 5 4 7)
   (7 (1 5 6) 4 (2 5) (2 3 5) 9 (1 2) (3 6) 8)
   ((1 5 6) (1 5 6) 8 (2 4 5 7) (2 3 4 5 7) (2 4) 9 (3 6) (1 2))
   ((2 6 8 9) 3 (6 9) 1 (2 4 8 9) 7 (2 4 8) 5 (2 4 6 9))
   ((1 2 5 9) (1 5 8 9) (1 5 7 9) (2 4) (2 4 9) 6 (2 3 4 7) (7 8 9) (2 3 4 9))
   ((2 6 8 9) 4 (6 7 9) 3 (2 8 9) 5 (2 7 8) 1 (2 6 9))
   ((1 3 9) (1 8 9) 2 (4 5 7 8) (4 5 7) (1 4) 6 (7 8 9) (3 9))
   (4 (1 6 8 9) (1 3 6 9) (2 7 8) (2 7) (1 2) (1 3 7) (7 8 9) 5)
   ((1 5 8) 7 (1 5) 9 6 3 (1 4 8) 2 (1 4)) ))

;;; [r3c6]=6=[r3c5]=5=[r3c8]-5-[r8c8]=5=[r9c7]=8=[r9c6]-8-[r3c6] => r3c6<>8 
(defparameter nice-06 #2a
  (((2 4 7) 5 (2 8) (4 7 9) (4 7 8 9) 1 6 (3 7 9) (3 7 8 9))
   (3 (1 4 7 8) 6 (4 7 9) (4 5 7 8 9) 2 (5 7 8) (1 7 9) (5 7 8 9))
   ((1 7) (1 7 8) 9 3 (5 6 7 8) (6 8) 2 (1 5 7) 4)
   ((7 9) (6 7 9) 4 5 3 (6 7 9) 1 8 2)
   ((1 2 9) (1 2 3 6 9) (2 3) 8 (6 9) 4 (5 7) (3 5 6 7 9) (3 5 9))
   (8 (3 6 7 9) 5 1 2 (6 7 9) 4 (3 6 9) (3 9))
   (6 (2 4 8 9) 1 (4 7 9) (4 7 8 9) 5 3 (2 7) (7 8))
   ((2 4 5) (2 3 4 8) (2 3 8) 6 (4 7 8) (3 8) 9 (2 5 7) 1)
   ((5 9) (3 9) 7 2 1 (3 8 9) (5 8) 4 6) ))

(defparameter nice-07 #2a
  (((1 2 4 5) 3 (1 2 4) (4 7 8) (1 5 8 9) (4 5 7 9) (7 8 9) (6 8) (4 6 9))
   ((4 5) 7 8 2 (5 9) 6 3 1 (4 9))
   (6 9 (1 4) (3 4 7 8) (1 3 8) (4 7) (7 8) 5 2)
   ((2 8) 5 7 9 (2 3) 1 4 (6 8) (3 6))
   ((1 2 8 9) 6 (1 2 9) (3 4) (2 3 5) (2 4 5) (8 9) 7 (1 3 9))
   ((1 4 9) (1 4) 3 6 7 8 5 2 (1 9))
   (3 8 (1 6 9) 5 (2 6 9) (2 9) (1 2) 4 7)
   (7 2 5 1 4 3 6 9 8)
   ((1 4 9) (1 4) (1 4 6 9) (7 8) (2 6 8 9) (2 7 9) (1 2) 3 5) ))

;;; > (permitted-methods)
;;;  (do-fundamental do-pattern-overlay-method do-cell-unique do-localization
;;;   do-n-tuples do-n-grid do-advanced-coloring)
;;; という設定で実行すると r#5,r#6 を観察できる。
(defparameter adv-coloring-01 #2a
  ((2 5 (3 8) 1 6 4 (3 8) 7 9)
   (6 (7 8) (7 8 9) (2 5) (3 9) (2 5) 1 (3 8) 4)
   ((3 9) 4 1 (7 8 9) (8 9) (3 7) 5 6 2)
   ((4 7) 1 (6 8) 3 5 9 (4 6 7 8) 2 (7 8))
   (5 (2 8) (2 6 8) 4 7 1 (6 8 9) (8 9) 3)
   ((4 7 9) 3 (4 7 9) 6 2 8 (4 7) 5 1)
   ((3 4 7) 6 5 (7 8 9) (4 8 9) (3 7) 2 1 (7 8))
   (1 (2 7) (2 4 7) (2 5 7 8) (3 4 8) (2 5) (7 8 9) (3 8 9) 6)
   (8 9 (2 3 7) (2 7) 1 6 (3 7) 4 5)))

;;; > (permitted-methods)
;;;  (do-fundamental do-pattern-overlay-method do-cell-unique do-localization
;;;   do-n-tuples do-n-grid do-advanced-coloring)
;;; という設定で実行すると r#2,r#5,r#6 を観察できる。
(defparameter adv-coloring-02 #2a
  ((9 2 3 4 (6 8) 7 (6 8) 1 5)
   (8 7 6 (1 3) 5 (1 3) 9 2 4)
   (5 (1 4) (1 4) 2 (6 8 9) (6 9) (6 7 8) 3 (7 8))
   (7 6 9 (3 5 8) 2 (3 5) 1 4 (3 8))
   (4 3 2 (1 6 8) (1 6 7) (1 6) (7 8) 5 9)
   (1 8 5 (3 9) (7 9) 4 2 6 (3 7))
   ((3 6) 9 8 (5 6) 4 2 (3 5) 7 1)
   (2 (1 5) 7 (1 5 9) 3 (1 5 9) 4 8 6)
   ((3 6) (1 4 5) (1 4) 7 (1 6) 8 (3 5) 9 2)))

;;; > (permitted-methods)
;;;  (do-fundamental do-pattern-overlay-method do-cell-unique do-localization
;;;   do-n-tuples do-n-grid do-advanced-coloring)
;;; という設定で実行すると r#1,r#2,r#5 を観察できる。
(defparameter adv-coloring-03 #2a
  ((1 2 6 7 3 9 8 4 5)
   ((5 8) 4 7 6 (2 5 8) (2 5 8) 3 9 1)
   (9 (3 8) (3 5) 4 (1 8) (1 5 8) 7 6 2)
   ((2 6) (1 3) (1 3) 8 (2 6) 4 5 7 9)
   ((6 7) 5 4 (1 3 9) (1 6 7 9) (1 3 6) 2 (1 3 8) (3 6 8))
   ((2 6 7) 9 8 5 (1 2 6 7) (1 2 3 6) 4 (1 3) (3 6))
   (3 6 (1 5) 2 4 (1 5 8) 9 (5 8) 7)
   (4 (1 8) 9 (1 3) 5 7 6 2 (3 8))
   ((5 8) 7 2 (3 9) (5 6 8 9) (3 5 6 8) 1 (3 5 8) 4)))

;; from http://www.menneske.no/sudoku/eng/showpuzzle.html?number=1976940
;;; > (permitted-methods)
;;;  (do-fundamental do-pattern-overlay-method do-cell-unique do-localization
;;;   do-n-tuples do-n-grid do-advanced-coloring)
;;; という設定で実行すると r#2,r#5,r#6 を観察できる。
(defparameter adv-coloring-04 #2a
  ((1 8 (4 5 7) 6 (4 5) 2 (4 7) 9 3)
   ((2 3) (3 5) (4 5 7) 8 (4 5 9) (5 9) (2 4 7) 1 6)
   ((2 9) (4 9) 6 7 3 1 5 (2 4) 8)
   (4 2 9 3 1 8 6 7 5)
   (6 7 3 2 (5 9) (5 9) 1 8 4)
   (5 1 8 4 6 7 9 3 2)
   ((8 9) (4 9) 1 5 2 3 (4 8) 6 7)
   (7 (3 5) (4 5) 1 8 6 (2 3 4) (2 4) 9)
   ((3 8) 6 2 9 7 4 (3 8) 5 1)))

;; Almost-Locked set sample
;; Doubly-linked. ALS-1 = (r4c2 r4c3 r5c1 r6c1), ALS-2 = (r4c6). r5c3<>5,r5c3<>9,r6c2<>5,r7c1<>5.
(defparameter als-01 #2a
  ((2 6 4 (3 7) (3 7) 8 1 5 9)
   (1 (5 9) (5 9) 4 2 6 (7 8) (3 7 8) (3 7 8))
   ((3 8) (7 8) (3 7 8) 5 1 9 6 4 2)
   (4 (7 8 9) (1 7 8) 2 5 (1 7) 3 (8 9) 6)
   ((5 9) 3 (1 2 5 7 9) 6 8 (1 7) 4 (2 7 9) (5 7))
   ((5 8) (2 5 7) 6 9 4 3 (2 5 7 8) (1 2 7 8) (1 5 7 8))
   ((3 5 8 9) (2 5 8 9) (2 3 5 8 9) 1 (3 7 9) (2 5) (2 5 7 8 9) 6 4)
   (7 1 (2 3 5 8 9) (3 8) 6 4 (2 5 8 9) (2 3 8) (3 5 8))
   (6 4 (2 3 5 8 9) (3 7 8) (3 7 9) (2 5) (2 5 7 8 9) (1 3 7 8) (1 3 5 7 8))))

;; Single-linked.
(defparameter als-02 #2a
  (((6 9) (3 4 5) (4 9) (4 5 6 9) 1 2 (3 4) 7 8)
   ((2 6 9) (3 4 8) (2 4 8 9) (4 6 9) 7 (4 9) (3 4) 5 1)
   (7 (4 5) 1 3 8 (4 5) 2 9 6)
   (8 6 (5 9) 7 (2 3) (3 5) 1 4 (2 9))
   (4 2 7 8 9 1 6 3 5)
   ((5 9) 1 3 (2 4 5) (2 4) 6 7 8 (2 9))
   (3 9 6 1 5 7 8 2 4)
   ((2 5) 7 (2 4 5) (2 4) 6 8 9 1 3)
   (1 (4 8) (2 4 8) (2 4 9) (2 3 4) (3 4 9) 5 6 7)))

;; Single-linked. ALS-1 = (r2c1 r3c1), ALS-2 = (r1c3 r2c3 r4c3 r5c3 r6c3). r6c1<>6.
(defparameter als-03 #2A
  ((4 (2 5 9) (2 5 7) 6 1 (5 8) 3 (7 8 9) (8 9))
   ((3 7) 1 (3 5 7) (3 9) 2 (5 8) (4 7 8 9) 6 (4 8 9))
   ((3 6) (6 9) 8 (3 4 9) (3 4 9) 7 2 5 1)
   (9 7 (1 2 3 6) 8 (4 6) (1 4) 5 (2 3) (2 3 4 6))
   ((2 8) 4 (2 6) 7 5 3 (8 9) 1 (2 6 8 9))
   ((1 3 6 8) (5 8) (1 3 5 6) (1 4 9) (4 6 9) 2 (4 8) (3 8) 7)
   (5 (2 8) (1 2 4 7 9) (1 2 3 4) (3 4 7) (1 4) 6 (2 3 7 8 9) (2 3 8 9))
   ((1 2 7) 3 (1 2 7 9) 5 8 6 (1 7 9) 4 (2 9))
   ((1 2 6 7 8) (2 6 8) (4 6 7) (1 2 3 4) (3 4 7) 9 (1 7 8) (2 3 7 8) 5)) )

;; Single-linked. ALS-1 = (r3c4 r3c5 r3c6 r3c8), ALS-2 = (r8c3 r8c4 r8c8 r8c9). r3c3<>6.
(defparameter als-04 #2A
  (((1 3) 2 7 (1 3 5) 8 4 6 (3 5 9) (3 5 9))
   (8 (1 3 6) (3 4 6) (1 2 3 5 7) 9 (1 5 6) (2 3 4 5 7) (2 3 5) (2 3 4 5 7))
   ((6 9) 5 (3 4 6 9) (2 3 7) (2 6 7) (3 6) (2 3 4 7 8) (2 3 8) 1)
   (5 4 (8 9) (1 9) (2 6 7) (1 8) (2 3 7) (2 3 6) (2 3 7))
   ((3 6 7 9) (3 7 9) 1 (2 4 7 9) (2 6 7) (5 6 9) (2 4 5 7) (2 5 6) 8)
   (2 (6 7 8) (6 8) (4 5 7) 3 (5 6 8) 9 1 (4 5 7))
   (4 (1 8) (3 5 8) 6 (1 5) (3 9) (2 3 5 8) 7 (2 3 5 9))
   ((6 7) (1 6 7 8) (3 5 6) (3 9) 4 2 (1 5 8) (3 5 8 9) (3 5 9))
   ((1 3 9) (1 9) 2 8 (1 5) 7 (1 3 5) 4 6)) )

;; Grid-Based Almost Locked Set sample.
;; GB-ALS(column based) = r7c3,r9c3,r2c6,r7c6,r8c6,r2c9,r7c9,r9c9 ==> r7c5<>8.
(defparameter als-05 #2A
  ((2 4 9 (7 8) 6 5 1 (7 8) 3)
   ((5 7) 3 (1 5 7) (1 4 7 8 9) (1 7 8 9) (1 4 7 8 9) 2 (4 6 8 9) (4 6 7 8 9))
   (8 6 (1 7) (1 3 4 7 9) (2 3 9) (2 4 9) (4 9) (4 7 9) 5)
   ((4 7 9) 2 (3 7) (1 3 7 8 9) (1 3 5 7 8 9) 6 (3 4 5 9) (1 3 4 5 7 9) (4 7 9))
   ((4 7 9) 8 (3 6 7) 2 (1 3 5 7 9) (1 7 9) (3 4 5 6 9) (1 3 4 5 6 7 9) (4 6 7 9))
   ((5 7 9) 1 (3 5 6 7) (3 9) 4 (7 9) 8 2 (6 7 9))
   ((1 3 6) 9 (2 8) 5 (1 8) (1 4 8) 7 (3 6 8) (2 4 6 8))
   ((3 6) 5 4 (6 7 8 9) (2 7 8 9) (2 7 8 9) (3 6 9) (3 6 8 9) 1)
   ((1 6) 7 (2 8) (1 4 6 8 9) (1 8 9) 3 (4 5 6 9) (4 5 6 8 9) (2 4 6 8 9))))

;; Grid-Based Almost Locked Set Sashimi example.
;; r6c8<>6.
(defparameter als-06 #2A
  (((5 6 9) 7 4 (3 6 9) 2 (3 9) (5 9) 8 1)
   (2 1 (6 9) 5 (4 6 9) 8 3 (4 6 9) 7)
   (8 3 (5 6 9) 1 (4 6 9) 7 (5 6 9) 2 (4 6 9))
   ((5 9) 2 7 4 8 6 1 3 (5 9))
   (4 (6 8) 1 (3 9) (5 9) (3 5 9) (6 8) 7 2)
   ((5 6 9) (5 6 8 9) 3 2 7 1 (6 8 9) (4 5 6 9) (4 5 6 9))
   (3 4 8 (6 9) 1 2 7 (5 6 9) (5 6 9))
   (1 (5 6 9) (5 6 9) 7 3 4 2 (6 9) 8)
   (7 (6 9) 2 8 (5 6 9) (5 9) 4 1 3)))

;; Grid-Based Almost Locked Set.
;; r1c1<>8.
(defparameter als-07 #2A
  (((6 8 9) (1 2 8 9) (1 2 6 9) 7 (3 6 8 9) (3 6 8 9) (1 6 8 9) 5 4)
   (7 (1 4 8 9) (1 4 6 9) (6 8 9) 2 5 (1 6 8 9) (6 8 9) 3)
   (5 3 (6 9) (6 8 9) 1 4 (6 8 9) (2 7) (2 7))
   ((4 8 9) 6 (1 2 4 9) (1 2) 5 (8 9) 7 3 (1 2 9))
   ((3 9) (1 2 9) 5 4 (3 6 9) 7 (6 8 9) (2 6 8 9) (1 2 6 9))
   ((3 8 9) (1 2 8 9) 7 (1 2) (3 6 8 9) (3 6 8 9) 5 4 (1 2 6 9))
   (1 7 3 (6 8 9) 4 (6 8 9) 2 (6 9) 5)
   (2 5 8 3 (6 9) 1 4 (6 7 9) (6 7 9))
   ((4 6 9) (4 9) (4 6 9) 5 7 2 3 1 8)))

;; this board, from sample-board-10, can not resolved by Ver.5.0.2
;; > (find-logical-path sample-board-10)
;; nil
;; 187
;; > (evil-boards)
(defparameter evil-01 #2A
  ((1 (2 5 6 8) (2 4 6 8) (4 5 8) (3 4 5) 7 (2 4 6) 9 (3 4 6))
   ((4 5 7) 3 (4 6) (1 4 5 9) 2 (1 5 9) (1 4 6 7) (4 6 7) 8)
   ((2 4 7 8) (2 7 8) 9 6 (1 3 4) (1 3 8) 5 (2 3 4 7) (1 3 4))
   ((2 4 7 8) (2 7 8) 5 3 (1 6 7) (1 2 6) 9 (4 6 7 8) (1 4 6))
   ((4 7 9) 1 (3 4) (5 7 9) 8 (5 6 9) (4 6 7) (3 4 5 6 7) 2)
   (6 (2 7 8 9) (2 3 8) (1 2 5 7 9) (1 5 7 9) 4 (1 7 8) (3 5 7 8) (1 3 5))
   (3 (2 5 6 8 9) (2 6 8) (2 4 5 7 8) (4 5 6 7 9) (2 5 6 8) (2 4 6 8) 1
      (4 5 6 9))
   ((2 5 8 9) 4 1 (2 5 8 9) (3 5 6 9) (2 3 5 6 8 9) (2 6 8) (2 5 6 8) 7)
   ((2 5 8 9) (2 5 6 8 9) 7 (1 2 4 5 8) (1 4 5 6 9) (1 2 5 6 8) 3 (2 4 5 6 8)
    (4 5 6 9))))

;; 次のmarvin-01の途中で現れる盤面。
(defparameter evil-02 #2A
  (((7 8) 3 1 9 (5 7 8) 2 4 (5 7 8) 6)
   (9 (5 6 7) (5 8) (1 3 5 6 8) (1 5 6 7 8) 4 (2 3 7 8) (2 5 7 8) (2 5 7 8))
   ((4 6 7 8) (4 5 6 7) 2 (3 5 6 8) (5 6 7 8) (5 6 7) (3 7 8 9) (5 7 8 9) 1)
   ((2 4 6 7) 9 3 (4 5 6 8) (5 6 8) (5 6) (2 6 7) 1 (2 4 5 7))
   (5 1 (4 6) 7 2 3 (6 8 9) (4 6 8 9) (4 8))
   ((2 4 6 7) 8 (4 6 7) (4 5 6) 9 1 (2 6 7) (2 4 5 6 7) 3)
   (3 (2 4 6 7) (4 6 7) (1 6) (1 6 7) 8 5 (2 4 6 7) 9)
   ((1 4 6 7 8) (4 5 6 7) (5 8) 2 3 9 (1 6 7 8) (4 6 7 8) (4 7 8))
   ((1 6 7 8) (2 6 7) 9 (5 6) 4 (5 6 7) (1 2 6 8) 3 (2 7 8))))

;; evil-02の元の問題はmixi内のトピック「難しい問題ですよ」で「Marvin＠空港閉鎖」さんが
;; 出題した次の問題。
(defparameter marvin-01 #2A
  ((0 0 1 9 0 0 4 0 6)
   (9 0 0 0 0 4 0 0 0)
   (0 0 2 0 0 0 0 0 1)
   (0 0 3 0 0 0 0 1 0)
   (5 0 0 7 2 0 0 0 0)
   (0 8 0 0 9 0 0 0 3)
   (3 0 0 0 0 8 5 0 9)
   (0 0 0 2 0 0 0 0 0)
   (0 0 9 0 4 0 0 3 0)))

(defvar *sudoku-game-name-list*
  '(sample-board-1 sample-board-2 sample-board-3 sample-board-4 sample-board-5
    sample-board-6 sample-board-7 sample-board-8 sample-board-9 sample-board-10 Inkala
    tuples-sample from-mixi-lm nice-01 nice-02 nice-03 nice-04 nice-05 nice-06 nice-07
    adv-coloring-01 adv-coloring-02 adv-coloring-03 adv-coloring-04 als-01 als-02 als-03 als-04
    als-05 als-06 als-07 evil-01 evil-02 marvin-01)
  )

(defvar *sudoku-game-list* (mapcar #'(lambda (x) (list x (eval x))) *sudoku-game-name-list*))
(defvar *sudoku-game-list-backup* (copy-seq *sudoku-game-list*))

(defparameter *sample-boards*    ;;バッチ・テスト用。(dolist (i *sample-boards*) (stat i))
  (list sample-board-1 sample-board-2 sample-board-3 sample-board-4 sample-board-5
        sample-board-6 sample-board-7 sample-board-8 sample-board-9 sample-board-10))

(defparameter *sample-nice*              ;バッチ・テスト用。(dolist (i *sample-nice*) (stat i))
  (list nice-01 nice-02 nice-03 nice-04 nice-05 nice-06 nice-07))
; (list nice-01 nice-02))

;;; 各種手筋を実現する関数名のリスト。
;;; (easy-method-first)が[t]ならリストの左側ほど「易しい」手筋と見なして優先的に使用する。
;;; (easy-method-first)と(think-depth)が[nil]なら手筋を(permitted-methods)の順に適用する。
;;; (think-depth)が数値[n]なら[n]手の範囲で「最善」の手筋の組合せを探して適用する。
(defparameter *all-methods*
  '(do-fundamental do-localization do-n-tuples do-n-grid do-almost-locked-set
    do-grid-based-almost-locked-set do-pattern-overlay-method do-advanced-coloring do-nice-loop))
(defvar *permitted-methods* *all-methods*) ;;既定値。

(defun numberplace (board)
"ナンプレを解くプログラムのエンジン部分。解のリストを返す。
need-multiple-answerがnilの場合は唯ひとつの解を返す。
ただし解がない場合は、いずれの場合も[nil]を返す。"
  (set-board-size (board-size board))
  (when (permit-cheat)
    (make-cheat-board board)
    (reset-counter) )
  (save-env)
  (catch 'search-finished (numberplace-sub board))
  (restore-env)
  (return-from numberplace (answer)))

(defun numberplace-sub (board)
  (let (p)
    (setf p (simple-numberplace board))
    (cond
      ((finished-p p) (answer p))
      ((conflict-p p) (answer nil))
      (t (do-trial-and-error p)))))

(defun numberplace-solver (board)
  "解を見やすく出力する。"
  (let ((p nil) rperm n r)
    (board-print-counter 0)
    (set-board-size (board-size board))
    (reset-counter)
    (when (>= (explanation-level) 10)
      (format t "次のボードに対する解を探します。~%")
      (finish-output)
      (print-board board))
    (when (think-depth)
      (setf n (length (permitted-methods)))
      (setf r (think-depth))
      (setf rperm (repeated-permutation n r))
      (format t "*~d手先まで読んで最善の手筋を探索します。" r)
      (format t "約~d倍の時間が掛かります。~%" (length rperm))
      (finish-output)
      )
    (cond
      ((null (check-initial-pattern board))
       (setf p nil))
      (t (setf p (numberplace board))))
    (if (not (listp p)) (setf p (list p)))
    (cond
      ((null p)
       (format t "この問題の正解を発見できません。")
       (format t "(help)を参照してレベルを設定して下さい。~%")
       (finish-output)
       )
      (t (format t "~dコの解がありました。~%" (length p))
         (dolist (brd p)
           (print-board brd)
           (if (print-chunk) (print-chunk brd))
           (if (>= (length p) 2) (terpri)) )))))

(defun stat (board)
"複雑さ(難易度)の指標となる実行情報を表示する。"
  (board-print-counter 0)
  ;;(when (permit-cheat) (make-cheat-board board))
  (time (numberplace-solver board))
  (format t "試行錯誤関数の実行回数は~d回, 探索深さの最大値は~dでした。~%" (exec-count) (max-depth))
  (when (> (method-count) 0)
    (format t "手筋適用回数は~d回, 平均難易度は~,2f, 最大難易度は~d, 合計難易度は~dでした。~%"
            (method-count) (float (/ (total-score) (method-count))) (max-score) (total-score))))

(defun teach (board &optional (level 11))
"解法過程を解説とボード付きで出力する。"
  (save-env)
  (print-check t)
  (check-backtrack-point t)
  (explanation-level level)
  (stat board)
  (restore-env)
  (return-from teach t))

(defun simple-answer (board)
"問題＋候補絞り込み後のボード＋解答。"
  (let (p)
    (set-board-size (board-size board))
    (save-env)
    (setf p (simple-answer-sub board))
    (restore-env)
    (return-from simple-answer p)))

(defun simple-answer-sub (board)
  (let ((p nil))
    ;;(need-multiple-answer t)
    (check-backtrack-point nil)
    (pause nil)
    (board-print-counter 0)
    (format t "次の問題の解を探します。~%")
    (print-board board)
    (force-output)
    (setf p (simple-numberplace board))
    (format t "初期状態の確定値により各マスの候補は次のように絞り込まれました。~%")
    (if (finished-p p) (print-board p) (print-normal p))
    (force-output)
    (cond
      ((finished-p p)
       (format t "試行錯誤なしで解に到達しました。唯一の解です。~%"))
      (t
       (format t "試行錯誤も行って最終的な解を探索します。~%")
       (numberplace-solver board)))))

(defun bruteforce-solver (board)
"Brute force Method(速い)。"
  (let (brd)
    (setf brd (new-board board))
    (save-env)
    (permit-cheat nil)
    (print-check nil)
    (explanation-level 0)
    (plot-level nil)
    (check-backtrack-point nil)
    (easy-method-first t)
    (auto-trim-level 100)
    (chain-trim t)
    (trim-every-time t)
    (n-grid-limit 0)
    (tuples-limit 0)
    (think-depth nil)
    (permitted-methods '(do-fundamental))
    (setf brd (numberplace brd))
    (restore-env)
    (answer nil)
    (return-from bruteforce-solver brd)))

(defun make-cheat-board (board)
"[bruteforce-solver]で正解を用意する。"
  (setf *cheat-board* (bruteforce-solver board))
  (if (listp *cheat-board*) (setf *cheat-board* (first *cheat-board*))))

(defun cheat-board (i j)
"作成しておいた正解を参照する。"
  (aref *cheat-board* i j))

(defun permit-cheat (&optional (val t sw))
"試行錯誤[do-trial-and-error]を行う際に未確定セルの値を実際に試行錯誤するか
[bruteforce-solver]で作成しておいた「正解」を使うかを設定する。
引数なしで使用すると現在の設定値を返す。"
  (cond
    ((null sw) *permit-cheat*)
    (t (setf *permit-cheat* val) )))

(defun plot (board &optional (level 2))
" 解法手順ごとに「難易度」をグラフ表示する(テキスト)。
level=[0]は[難易度]のみ。他ソフトへのデータ受け渡し用途を想定。
level=[1]は[手順番号]と[難易度]、[グラフ(テキスト)]
level=[2]は[手筋名称]、[手順番号]、[難易度]、[グラフ(テキスト)]"
  (save-env)
  (plot-level level)
  (explanation-level 0)
  (format t "次の問題の解法過程をグラフ化します。~%")
  (print-board board)
  (force-output)
  (stat board)
  (restore-env)
  (return-from plot t))

(defun pencil-mark (&optional (val nil switch))
"すべての確定値に対して行・列・ブロックの候補から確定値を取り除く。
ペンシル・マーク(pencil mark)とも呼ばれる。手動で解く場合の補助用。
ボード型以外の引数を与えると候補数字をセル内の固定位置に表示するか
どうかを設定する。引数なしの場合は現在の設定値を返す。"
  (cond
    ((null switch)
     *pencil-mark*)
    ((board-p val)
     (print-pencil-mark val))
    (t (setf *pencil-mark* val))))

(defun print-pencil-mark (board)
  (save-env)
  (pencil-mark t)
  (print-normal (pm board))
  (restore-env)
  (return-from print-pencil-mark t))

(defun ppm (board)
"[print-pencil-mark]の短縮表記。"
  (print-pencil-mark board))

(defun pm (board)
"ペンシルマーク形式のボードを返す。"
  (let (brd)
    (set-board-size (board-size board))
    (save-env)
    (auto-trim-level 100)
    (chain-trim t)
    (setf brd (do-trim (listup-all-possibility board)))
    (restore-env)
    (return-from pm brd)))

(defun set-pencil-mark (&optional (val t))
  (pencil-mark val))

(defun color-mode (&optional (val 0 sw))
"3D Medusa (Advanced Coloring)の盤面出力で候補数字をカラー出力するレベルを設定する。
レベル1以上では xterm互換ターミナルが必要。Windowsのcmd.exeは xtermのカラー表示機能
をサポートしていないのでレベル1以上では画面が乱れる。引数の意味は
   2 = 彩色対象候補数字をカラーで出力。
   1 = 彩色対象候補数字をカラーの短縮色名で出力。
   0 = 彩色対象候補数字を短縮色名で出力(完全モノクロ)。
カラー情報はコピー&ペーストでは他アプリにコピーできないが出力レベル[0]または[1]で出力
しておけば文字情報として色情報をコピーできる。
出力レベルが[0]または[1]の場合、Advanced Coloringの盤面をペンシルマーク形式で出力する。
他の手筋の盤面出力はペンシルマークの設定に従う。ペンシルマークの設定値は変更しない。
引数なしで実行すると現在のカラー出力レベルを返す。"
  (cond
    ((or (null sw) (null val))
     (identity *color-mode-level*))
    ((and (zero-or-positive-integerp val) (>= val 2))
     (setf *color-mode-level* 2))
    ((and (zero-or-positive-integerp val) (>= 1 val 0))
     (setf *color-mode-level* val) )
    (t nil)))

(defun als-show-all (&optional (val nil sw))
"[*ALS-show-all*]の値を表示・設定する。
[*ALS-show-all*]の値が[nil]ならAlmost Locked Setのすべての手筋を表示する。
[*ALS-show-all*]の値が[nil]でないならAlmost Locked Setの効率的手筋のみを表示する。
効率的手筋とは、同一の候補数字を削除できる場合
  ・[single-linked]の方が[doubly-linked]よりも効率的。
  ・2つのALSのセル数の2乗の和が小さい方が効率的。
  ・より多くの候補数字を一括削除できる方が効率的。
と定義する。"
  (cond
    ((null sw)
     (identity *ALS-show-all*))
    (t (setf *ALS-show-all* val))))

(defun show-color-board (&optional (val nil sw))
"[*show-color-board*]の値を表示・設定する。
[*show-color-board*]の値が[nil]なら解説ボードにカラー表示を使用しない。
[*show-color-board*]の値が[nil]でないなら解説ボードにカラー表示を使用する。"
  (cond
    ((null sw)
     (identity *show-color-board*))
    (t (setf *show-color-board* val))))

(defun als-show-stat (&optional (val nil sw))
"[*ALS-show-stat*]の値を表示・設定する(ALSに関する統計情報表示を設定する)。
[*ALS-show-stat*]の値が[nil]なら統計情報を表示しない。
[*ALS-show-stat*]の値が[nil]でないなら統計情報を表示する。"
  (cond
    ((null sw) *ALS-show-stat*)
    (t (setf *ALS-show-stat* val))))

(defun gb-als-show-all (&optional (val nil sw))
"[*GB-ALS-show-all*]の値を表示・設定する。
[*GB-ALS-show-all*]の値が[nil]ならGB-Almost Locked Setのすべての手筋を表示する。
[*GB-ALS-show-all*]の値が[nil]でないならGB-Almost Locked Setの効率的手筋のみを表示する。
効率的手筋とは、同一の候補数字を削除できる場合
  ・より多くの候補数字を一括削除できる方が効率的。
  ・2つのGB-ALSのセル数の2乗の和が小さい方が効率的。
と定義する。"
  (cond
    ((null sw)
     (identity *GB-ALS-show-all*))
    (t (setf *GB-ALS-show-all* val))))

(defun als-check-limit (&optional (val nil sw))
"[ALS-check-limit*]の値を表示・設定する。"
  (cond
    ((null sw) *ALS-check-limit*)
    (t (setf *ALS-check-limit* val))))

(defun novice-level (&optional (p t))
"ナンプレ初心者向きの設定。
localization=不使用、n-grid=不使用、tuples=不使用、配置確定法=不使用。
刈り込みが不十分だと解が得られない場合がある。「(novice-level t)」と
設定変更してから再度「(teach sample-board-6)」などとする。"
  (setf *selected-user-level* 'novice-level)
  (easy-method-first t) ;;易しい手筋を最優先で適用する。
  (need-multiple-answer t)
  (auto-trim-level 100)
  (chain-trim p)
  (trim-every-time t)
  (print-chunk t)
  (space-char-is ".")   ;;盤面中の空数字の初期値。(space-char-is ch)で[ch]に変更。
  (n-grid-limit 0)
  (tuples-limit 0)
  (think-depth nil)     ;;手筋の「先読み」は行わない。
  (permit-cheat nil)
  (permitted-methods '(do-fundamental))
  ;;(print-preset-level)
  (return-from novice-level t)
  )

(defun middle-level ()
"ナンプレ初級から中級者向きの設定。
localization=使用, n-grid=不使用, tuples=2国同盟まで使用, 配置確定法=不使用。"
  (setf *selected-user-level* 'middle-level)
  (easy-method-first nil)       ;;[nil]なら[permitted-methods]の順に手筋を適用することを繰り返す。
  (need-multiple-answer t)
  (auto-trim-level 100)
  (chain-trim t)
  (trim-every-time t)
  (print-chunk t)
  (space-char-is ".")   ;;盤面中の空数字の初期値。(space-char-is ch)で[ch]に変更。
  (n-grid-limit 0)
  (tuples-limit 2)
  (think-depth nil)     ;;手筋の「読み」は行わない。
  (permit-cheat nil)
  (permitted-methods '(do-fundamental do-localization do-n-tuples))
  ;;(print-preset-level)
  (return-from middle-level t)
  )

(defun senior-level (&optional (depth nil)) ;既定では先読みは行わない。
"ナンプレ中級から上級者向きの設定。
localization=使用, n-grid=2x2(x-wing)まで使用, tuples=3国同盟まで使用, 配置確定法=不使用。"
  (setf *selected-user-level* 'senior-level)
  (easy-method-first nil)       ;;[nil]なら[permitted-methods]の順に手筋を適用することを繰り返す。
  (need-multiple-answer t)
  (auto-trim-level 100)
  (chain-trim t)
  (trim-every-time t)
  (print-chunk t)
  (space-char-is ".")   ;;盤面中の空数字の初期値。(space-char-is ch)で[ch]に変更。
  (n-grid-limit 2)
  (tuples-limit 3)
  (think-depth depth)
  (permit-cheat nil)
  (ALS-show-all t)
  (als-show-stat t)
  (permitted-methods
   '(do-fundamental do-localization do-n-tuples do-n-grid do-almost-locked-set))
  ;;(print-preset-level)
  (return-from senior-level t)
  )

(defun advanced-level (&optional (depth nil)) ;既定では先読みは行わない。
"ナンプレ上級者向きの設定。
localization=使用, n-grid=3x3(swordfish)まで使用, tuples=3国同盟まで使用, 配置確定法=使用,
ALS=使用, Nice Loop=連鎖セル数5までで使用。"
  (setf *selected-user-level* 'advanced-level)
  (easy-method-first nil)       ;;[nil]なら[permitted-methods]の順に手筋を適用することを繰り返す。
  (need-multiple-answer t)
  (auto-trim-level 100)
  (chain-trim t)
  (trim-every-time t)
  (print-chunk t)
  (space-char-is ".")   ;;盤面中の空数字の初期値。(space-char-is ch)で[ch]に変更。
  (n-grid-limit 3)
  (tuples-limit 3)
  (max-nice-length 5)
  (max-nice-loops nil)  ;;各盤面で採用するNice Loopの最大数。[nil]は無制限。
  (capital-address t)   ;;セル・アドレスを大文字で表示する。
  (print-with-symbol-letter t);;Nice Loop経路を表示する際にラベル記号も表示する。
  (think-depth depth)
  (permit-cheat nil)
  (ALS-show-all t)
  (ALS-show-stat t)
  (permitted-methods
   '(do-fundamental do-pattern-overlay-method do-localization
     do-n-tuples do-n-grid do-almost-locked-set do-nice-loop))
  ;;(print-preset-level)
  (return-from advanced-level t)
  )

(defun machine-level (&optional (depth nil)) ;既定では先読みは行わない。
"ナンプレ超上級者向きの設定。
localization=使用, n-grid=上限なしで使用, tuples=上限なしで使用, 配置確定法=使用,ALS=使用,
Nice Loop=上限なしで使用。Advanced Coloring=使用。GB-ALS=使用。cheat=許可。複数解=探索せず。"
  (setf *selected-user-level* 'machine-level)
  (easy-method-first nil) ;;[nil]なら[permitted-methods]の順に手筋を適用することを繰り返す。
  (need-multiple-answer nil)
  (auto-trim-level 100)
  (chain-trim t)
  (trim-every-time t)
  (print-chunk t)
  (space-char-is ".") ;;盤面中の空数字の初期値。(space-char-is ch)で[ch]に変更。
  (n-grid-limit nil)
  (tuples-limit (floor *board-size* 2))
  (max-nice-length nil)
  (max-nice-loops nil) ;;各盤面で採用するNice Loopの最大数。[nil]は無制限。
  (capital-address nil) ;;セル・アドレスを大文字で表示する。
  (print-with-symbol-letter t) ;;Nice Loop経路を表示する際にラベル記号も表示する。
  (output-nice-graph nil) ;;GraphViz用のデータ・ファイル「LinkMap-xxx.gv」を生成するか否かを設定。
  (think-depth depth)
  (permit-cheat t)
  (ALS-show-all nil)
  (GB-ALS-show-all nil)
  (permitted-methods ;; 順序に意味がある。デフォルトではリスト順に手筋を適用する。
   '(do-fundamental do-pattern-overlay-method do-localization do-n-tuples do-n-grid
     do-almost-locked-set do-grid-based-almost-locked-set do-advanced-coloring do-nice-loop))
  ;;(print-preset-level)
  (return-from machine-level t)
  )

(defun selected-user-level ()
"設定されているユーザ・レベルを返す。
('novice-level 'middle-level 'senior-level 'advanced-level 'machine-level)"
  *selected-user-level*
  )

(defun speed-first ()
"速度最優先の設定。解説等の出力一切なし。
localization=不使用、n-grid=不使用、tuples=不使用、配置確定法=不使用。
(time (dolist (i *sample-boards*) (stat i)))::=(Real time: 5.736 sec)/コンパイル時"
  (print-check nil)
  (explanation-level 0)
  (check-backtrack-point nil)
  (novice-level t)
  ;;(print-preset-level)
  (return-from speed-first t)
  )

(defun enter-board (&optional (brd-size 9 sw))
"ボード・データを入力する。
ボードを表す配列を返すので (setf tmp (enter-board)) などとする。
実行時にボード・サイズを与えられるように修正。2011/07/08"
  (let (brd fmt tmp)
    (save-env)
    (cond
      ((zero-or-positive-integerp brd-size)
       (set-board-size brd-size))
      ((null sw)
       (set-board-size brd-size))
      (t
       (format t "ボードのサイズを数字で入力して下さい(9x9なら9)。 ")
       (finish-output)
       (setf brd-size (read))
       (clear-input)
       (when (not (zero-or-positive-integerp brd-size))
         (enter-board) ) ) )
    ;; ボードのサイズに応じて,必要な桁数をゼロ・パディングする表示用フォーマット文字列を作成する。
    ;; 9x9   ==> 1行目:
    ;; 16x16 ==> 01行目:
    (setf fmt (format nil "~~~d\,'0\d行目: " (width brd-size)))
    (block-size (isqrt brd-size))
    (setf brd (make-array (list *board-size* *board-size*)))
    (debug-write "enter-board" (format nil "*board-size*=~d~%" *board-size*))
    (format t "行ごとに入力します。空欄には「0」を入力してください。~%")
    (finish-output)
    (dotimes (i *board-size*)
      (format t fmt (1+ i))
      (finish-output)
      (dotimes (j *board-size*)
        (setf tmp (read))
	(when (member tmp '(quit q exit bye) :test #'equal)
	  (restore-env)
	  (return-from enter-board nil)
	  ) ;; end when
        (setf (aref brd i j) tmp)
        ) ;; end inner dotimes
      )   ;; end outer dotimes
    (restore-env)
    (return-from enter-board brd)
    ) ;; end let
  ) ;; end enter-board

(defun edit-board (board &optional (edit-exp-list nil))
  "ボード・データを編集する。
編集後のボードを表す配列を返すので (setf my-board (edit-board your-board)) などとする。"
  (let ((i nil) (j nil) (k nil))
    (set-board-size (board-size board))
    (save-env)
    (when (board-p board)
      (print-board board)
      (when (identity edit-exp-list)
	(setq board (edit-board-with-cell-expression board edit-exp-list))
	(return-from edit-board board)
	)
      (loop
        (format t "修正する行と列の番号を指定してください：")
        (finish-output)
        (setf i (read))
        (setf j (read))
        (clear-input)
        (format t "修正する値を指定してください：")
        (finish-output)
        (setf k (read))
        (clear-input)
        (setf (aref board (1- i) (1- j)) k)
        (print-board board)
        ;;(format t "続けますか？ (y/n) ")
        ;;(when (not (y-or-n-p)) (return board))))
        (when (not (query-y-or-n-p "続けますか？")) (return board))))
    (restore-env)
    (return-from edit-board board)
    ) ;; end let
  ) ;; end edit-board

(defun edit-board-with-cell-expression (brd edit-exp-list)
"[edit-exp] ::= (mustbe [cell] [determined candidate]) | (cannotbe [cell] ([candidate]+) ;
[edit-exp-list] ::= ([edit-exp]+) ;"
  (let (cell row col cand)
    (dolist (p edit-exp-list)
      (setq cell (second p))
      (setq row (first cell) col (second cell))
      (cond
	((equal (first p) 'mustbe)
	 (if (pure-listp (third p))
	     (setf (aref brd row col) (first (third p)))
	     (setf (aref brd row col) (third p))
	     ) ;; end if
	 )
	((equal (first p) 'cannotbe)
	 (setq cand (aref brd row col))
	 (if (integerp cand)
	     (setq cand (list cand))
	     )
	 (setf (aref brd row col) (sort (copy-seq (set-difference cand (third p) :test #'equal)) #'<))
	 )
	(t
	 (error "予期しない[edit-exp-list]です。")
	 )
	) ;; end cond
      ) ;; end dolist
    (return-from edit-board-with-cell-expression brd)
    ) ;; end let
  ) ;; end edit-board-with-cell-expression

(defun board2chunk (board)
"ボード型のデータを等価な文字列に変換する。
変換された文字列は[chunk2board]で元のボード型データに戻る。たとえば

#2A((0 0 0 0 0 0 0 0 0)
    (4 0 3 0 9 0 1 0 0)
    (0 2 0 6 0 8 0 0 0)
    (3 0 0 0 6 0 4 0 0)
    (0 7 0 0 0 2 0 0 0)
    (1 0 9 0 0 0 3 0 0)
    (0 5 0 2 0 6 0 0 0)
    (2 0 1 0 3 0 5 0 0)
    (0 0 0 0 0 0 0 0 0)) ==>
\"000000000403090100020608000300060400070002000109000300050206000201030500000000000\""
  (let (times bsize result fmt)
    (setf bsize (board-size board))
    (setf fmt (format nil "~~~d\,'0\d" (* bsize bsize)))
    (setf times (* (width bsize) 10))
    (setf result 0)
    (dotimes (i bsize)
      (dotimes (j bsize)
        (setf result (* result times))
        (incf result (aref board i j))))
    (return-from board2chunk (format nil fmt result))))

(defun board2rows (board)
" ボード型のデータを行単位で等価な文字列に変換する。
変換された文字列は[rows2board]で元のボード型データに戻る。たとえば

#2A((0 6 0 0 8 0 0 7 4)
    (7 3 0 0 0 9 0 1 2)
    (0 0 1 0 0 0 6 0 0)
    (0 0 0 3 0 5 0 2 0)
    (4 0 0 0 9 0 0 0 3)
    (0 8 0 6 0 2 0 0 0)
    (0 0 4 0 0 0 1 0 0)
    (3 5 0 7 0 0 0 6 8)
    (6 1 0 0 5 0 0 9 0)) ==>
(\"060080074\" \"060080074\" \"730009012\" \"001000600\" \"000305020\"
 \"400090003\" \"080602000\" \"004000100\" \"350700068\" \"610050090\")"
  (let (times bsize row result fmt)
    (setf bsize (board-size board))
    (setf fmt (format nil "~~~d\,'0\d" bsize))
    (setf times (* (width bsize) 10))
    (setf result nil)
    (dotimes (i bsize)
      (setf row 0)
      (dotimes (j bsize)
        (setf row (* row times))
        (incf row (aref board i j)))
      (push (format nil fmt row) result))
    (return-from board2rows (reverse result))))

(defun chunk2board (chunk &optional (size 9))
"[board2chunk]の逆変換を行う。既定のボード・サイズは9x9(各数字は1桁)。"
  (let (modulus brd lst)
    ;;(if (stringp chunk) (setf chunk (string-to-integer chunk)))
    (if (string-digit-p chunk) (setf chunk (string-to-integer chunk))) ;; 2023-12-13
    (setf modulus (* (width size) 10))
    (setf brd (make-array (list size size)))
    (setf lst nil)
    (dotimes (i (* size size))
      (push (mod chunk modulus) lst)
      (setf chunk (floor chunk modulus)))
    (dotimes (i size)
      (dotimes (j size)
        (setf (aref brd i j) (pop lst))))
    (return-from chunk2board brd)))

(defun rows2board (rows &optional (size 9))
"[rows2chunk]の逆変換を行う。既定のボード・サイズは9x9(各数字は1桁)。"
  (let (modulus brd lst)
    (setf brd (make-array (list size size)))
    (setf modulus (* (width size) 10))
    (setf lst nil)
    (dolist (row rows)
      ;;(if (stringp row) (setf row (string-to-integer row)))
      (if (string-digit-p row) (setf row (string-to-integer row))) ;; 2023-12-13
      (dotimes (i size)
        (push (mod row modulus) lst)
        (setf row (floor row modulus))))
    (setf lst (reverse lst))
    (dotimes (i size)
      (dotimes (j size)
        (setf (aref brd i (- size j 1)) (pop lst))))
    (return-from rows2board brd)))

(defun string-to-integer (str &optional (radix 10))
"0..zと空白文字、カンマ、ピリオドからなる39進数までの文字を対応する10進数値に変換する。
実行環境の文字コードに依存しない。"
  (let (lst result digit)
    (setf lst (mapcar #'digit-char-to-integer (concatenate 'list str)))
    (setf result 0)
    (setf digit 0)
    (dolist (i (reverse lst))
      ;; 基数より大きな数を表す「数字」が含まれていたら[nil]を返す。
      (if (>= i radix) (return-from string-to-integer nil))
      (incf result (* i (expt radix digit)))
      (incf digit)
      ) ;; end dolist
    (return-from string-to-integer result)))

(defun digit-char-to-integer (ch)
"0..zと空白文字、カンマ、ピリオドまでの39進数の文字を対応する数値に変換する。実行環境の文字コードに依存しない。
空白文字、カンマ、ピリオドを加えたのは英文を数値化する遊びのため。

[7]> (string-to-integer \"this is a pen.\" 39)
14219978299571224305098
"
  (case (char-downcase ch)
    (#\0 0)
    (#\1 1)
    (#\2 2)
    (#\3 3)
    (#\4 4)
    (#\5 5)
    (#\6 6)
    (#\7 7)
    (#\8 8)
    (#\9 9)
    (#\a 10)
    (#\b 11)
    (#\c 12)
    (#\d 13)
    (#\e 14)
    (#\f 15)
    (#\g 16)
    (#\h 17)
    (#\i 18)
    (#\j 19)
    (#\k 20)
    (#\l 21)
    (#\m 22)
    (#\n 23)
    (#\o 24)
    (#\p 25)
    (#\q 26)
    (#\r 27)
    (#\s 28)
    (#\t 29)
    (#\u 30)
    (#\v 31)
    (#\w 32)
    (#\x 33)
    (#\y 34)
    (#\z 35)
    (#\Space 36)
    (#\, 37)
    (#\. 38)
    (t nil)))

(defun string-digit-p (str &optional (radix 10))
"数字だけからなる文字列か調べて真偽を返す。空文字列なら[nil]を返す。
第2引数で指定された基数の範囲を超える文字を使っていた場合も[nil]を返す。"
  (if (not (stringp str)) (return-from string-digit-p nil))
  (if (zerop (length str)) (return-from string-digit-p nil))
  (dotimes (i (length str))
    (when (not (digit-char-p (char str i) radix))
      (return-from string-digit-p nil))
    )
  (return-from string-digit-p t))

(defun integer-to-string (num &optional (radix 10))
"[radix]進の整数を[radix]進数の文字列に変換する。
ex.
[268]> (integer-to-string 255 16)
\"ff\"
[269]> (integer-to-string 3 2)
\"11\"
[270]> (integer-to-string 255 36)
\"73\"
[271] (integer-to-string \#16rff 16)
\"ff\"
"
  (let (str quot rema)
    (setq str nil)
    (if (not (integerp num)) (return-from integer-to-string nil))
    (loop
      (multiple-value-setq (quot rema) (floor num radix))
      (push (integer-to-digit-char rema) str)
      (setq num quot)
      (if (zerop num) (return))
      ) ;; end loop
    (return-from integer-to-string (concatenate 'string str))
    )	;; end let
  ) ;; end integer-to-string

(defun integer-to-digit-char (n &optional (char-case 'downcase sw)) ;; or 'upcase
  "0から38までの39進数までの「数字」を返す。"
  (let (result)
    (setq result
	  (case n
	    (0 #\0)
	    (1 #\1)
	    (2 #\2)
	    (3 #\3)
	    (4 #\4)
	    (5 #\5)
	    (6 #\6)
	    (7 #\7)
	    (8 #\8)
	    (9 #\9)
	    (10 #\a)
	    (11 #\b)
	    (12 #\c)
	    (13 #\d)
	    (14 #\e)
	    (15 #\f)
	    (16 #\g)
	    (17 #\h)
	    (18 #\i)
	    (19 #\j)
	    (20 #\k)
	    (21 #\l)
	    (22 #\m)
	    (23 #\n)
	    (24 #\o)
	    (25 #\p)
	    (26 #\q)
	    (27 #\r)
	    (28 #\s)
	    (29 #\t)
	    (30 #\u)
	    (31 #\v)
	    (32 #\w)
	    (33 #\x)
	    (34 #\y)
	    (35 #\z)
	    (36 #\Space)
	    (37 #\,)
	    (38 #\.)
	    (t nil))
	  )
    (cond
      ((null result)
       nil
       )
      ((null sw)
       (return-from integer-to-digit-char result)
       )
      ((equal char-case 'downcase)
       (return-from integer-to-digit-char result)
       )
      ((equal char-case 'upcase)
       (return-from integer-to-digit-char (char-upcase result))
       )
      (t
       nil
       )
      ) ;; end cond
    ) ;; end let
  ) ;; end integer-to-digit-char

(defun chunk-p (str)
"引数の文字列がchunk型のデータか否かを返す。"
  (cond
    ((not (stringp str)) nil)
    ((/= (length str) (* (board-size) (board-size))) nil)
    (t (string-digit-p str))
    )
  )

(defun print-board (board)
"ボードをプリントする。"
  (cond
    ((and board (listp board))
     (dolist (i board) (print-board i)))
    ((board-p board)
     (print-board-sub board)))
  (return-from print-board t))

(defun print-board-sub (board)
  (set-board-size (board-size board))
  (save-env)
  (if (print-mini) (print-mini board) (print-normal board))
  (restore-env)
  (return-from print-board-sub t))

(defun print-normal (&optional (brd nil switch))
"候補数字付きの標準サイズでボードを出力する。
・ボード型以外の引数の場合は、[nil]なら[print-board]で出力するとき小型のボードで出力する。
  [nil]以外なら[print-board]で出力する際、標準サイズのボードで出力する。
・引数なしなら現在の設定値を返す。(print-normal)=(not (print-mini))。
・[x]がボード型でないなら (print-normal x)=(not (print-mini (not x)))。

[board]       ::= [cell]の*board-size* x *board-size*の2次元配列 ;
[cell]        ::= [nil] | [number] | ([color] [number]) | ([color] [candidate]) ;
[candidate]   ::= [number] | ([color] [number]) | ([candidate]...) ;

#2A(((2 5 7) (5 6 7) (5 6 7) (1 4 5 6 7) 8 3 9 (2 4 5 6) (1 2 5))
    (1 (5 6 7 9) (5 6 7 8 9) (4 5 6 7 9) (2 4 6 9) (2 4 5 6 7) (4 5 6 8) 3 (2 5 8))
    ((2 3 5 8 9) (3 5 6 9) 4 (1 5 6 9) (1 2 6 9) (1 2 5 6) (1 5 6 8) 7 (1 2 5 8))
    ((5 7 8 9) 4 2 (1 5 6 8 9) 3 (1 5 6 8) (5 6 7 8) (5 6 8 9) (5 7 8 9))
    (6 (1 3 5 7 9) (1 (red 3) 5 7 8 9) (1 5 8 9) (1 2 9) (1 2 5 8) (3 5 7 8) (2 5 8 9) 4)
    ((blue (3 5 8 9)) (3 5 9) (3 5 8 9) (4 5 6 8 9) 7 (2 4 5 6 8) (3 5 6 8) 1 (2 3 5 8 9))
    ((3 4 5 7 9) 2 (1 3 5 6 7 9) (1 3 4 6 7 8) (1 4 6) (1 4 6 7 8) (1 3 4 5 7 8) (4 5 8 9) (1 3 5 7 8 9))
    ((3 4 5 7) 8 (1 3 5 6 7) (1 3 4 6 7) (1 4 6) 9 2 (4 5) (1 3 5 7))
    ((3 4 7 9) (1 3 7 9) (1 3 7 9) 2 5 (1 4 7 8) (1 3 4 7 8) (4 8 9) 6))
==> r5c3の[3]が[red]に、r6c1のセル全体が[blue]で彩色される。セル全体の彩色は2011-07-23に実験的に追加。

セル全体に対する彩色情報は[board」と同サイズの配列[colored-cell]の該当セルに色名を移すことで記録する。
色名情報を移動した後の[board]配列の各セル内の情報は{[number] | ([color] [number])}...。"
  (cond
    ((null switch)
     (not (print-mini)))
    ((board-p brd)
     (set-board-size (board-size brd))
     (print-normal-2 (new-board brd))
     (new-page)
     )
    (t (not (print-mini (not brd))))))

(defun print-normal-2 (board)
    (print-normal-sub board "#" "|" "#") )

(defun print-normal-sub (board outer-ch sep-ch block-corner-ch)
"セル全体を彩色するかどうかは[colored-cell]配列に設定する。
2次元配列の該当する位置が[nil]ならセルの彩色なし。[色名]ならセル全体を[色名]で彩色する。"
  (let (p-board p q lst wd fmt fmt2 chr colored-brd cell-color color cell-row cell-col tmp)
    (setf p-board nil)
    (setf p nil q nil)
    (setf lst nil)
    (board-print-counter (1+ (board-print-counter)))
    (set-board-size (board-size board))
    (setf wd (width *board-size*)) ;; 0から[*board-size*]までの10進数を表現するのに必要な桁数。
    (setf fmt  (format nil "~~~d\,'0\d" wd)) ;; wd=1 ==> fmtは"~1,'0d" もし16x16のナンプレなら2桁0パディング。
    (setf fmt2 (format nil "~~~d\,\a" wd))   ;; wd=1 ==> fmt2は"~1,a"
    (setf colored-brd (make-array (list *board-size* *board-size*) :initial-element nil))
    ;; 1マスの大きさは[*block-size*^2]。9x9のナンプレなら1マスに1〜9が含まれるので3x3。
    ;; これが[(*board-size*)^2]個ある。
    (setf p-board ;; [board]型データの候補数字を(9x9ナンプレの場合なら)3x3のマスの中に割り振るための配列。
          (make-array (list (* *block-size* *board-size*) (* *block-size* *board-size*))))
    (dotimes (i (* *block-size* *board-size*))
      (dotimes (j (* *block-size* *board-size*))
        ;; [p-board]のセル内の全ての候補数字表示位置を設定された空白文字で初期化する。
        (setf (aref p-board i j) (space-char-is)) ;; デフォルトではピリオド[.]。
        )                                         ;; end dotimes
      )                                           ;; end dotimes


    ;; ([color] [candidate]) ==> [candidate]に変換。セル全体を彩色する[color]は[colored-brd]に保存。
    ;; 以後、[board]の内容は(pure-candidate-list-p)で[t]となる内容。
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)

        (debug-write "print-normal-sub-1" (format nil "(aref [board] ~d ~d) = ~s~%" i j (aref board i j)))
        
        (when (pure-listp (aref board i j))

          ;; *セル全体を彩色するかどうかの情報を保存する2次元配列[colored-brd]を設定する。
          (when (member (first (aref board i j)) *authorized-color-list*)
            (setf color (first (aref board i j)))
            (debug-write "print-normal-sub-2" (format nil "color=~a" color))
            ;; セル全体に対する色指定を内部色に変換。2024-01-26
            (if (member color *user-authorized-color-list*) (setf color (true-color color)))
            (setf (aref colored-brd i j) color)
            (debug-write "print-normal-sub-3" (format nil "color=~a" color))
            (setf (aref board i j) (rest (aref board i j)))
            ) ;; end when

          (setf tmp nil)
          (dolist (candidate (aref board i j)) ;; 候補数字の色名も内部色に変換。2024-01-26
            (cond
              ((and ;; ([color] [candidate])形式で[color]は[*parity-color-list*]のキー。
                (colored-candidate-p candidate)
                (member (first candidate) *user-authorized-color-list*)
                )
               (push
                (list (true-color (first candidate)) (second candidate)) tmp)
               )
              ((and ;; ([color] [candidate])形式だが[color]は[*parity-color-list*]のキーではない。
                (colored-candidate-p candidate)
                (not (member (first candidate) *user-authorized-color-list*))
                )
               (push candidate tmp)
               )
              ((integerp candidate)
               (push candidate tmp)
               )
              (t (error "print-normal-sub:許されていない色名が使われています。~a" candidate))
              )                                 ;; end cond
            )                                   ;; end dolist
          (setf (aref board i j) (reverse tmp)) ;; [board]には色名を内部名に変換した候補数字をセット。
          (debug-write "print-normal-sub-4" (format nil "(aref [board] ~d ~d) = ~s~%" i j (aref board i j)))
          ;; 色指定を含むかも知れない候補数字を整列する。
          (when (pure-candidate-list-p (aref board i j))
            (setf (aref board i j) (sort (aref board i j) #'colored-lessp))
            ) ;; end when
          )

        (setf lst (aref board i j))
        (cond
          ((integerp lst)
           (setf lst (- lst)) ;; 確定値は区別のため負の値としておく。
           )
	  ((and ;; it is like (5).
	    (pure-listp lst)
	    (= (length lst) 1)
	    (integerp (first lst))
	    )
	   (setf lst (- (first lst))) ;; セル中央に数字で表示されるように設定。
	   )
          ((and
	    (pure-candidate-list-p lst) ;; it's like ((blue 3)). 2024-03-16 bug fix
	    (= (length lst) 1)
	    (colored-candidate-p (first lst))
	    )
	   (setf lst (- (second (first lst)))) ;; セル中央に数字で表示されるように設定。
           )
          ((and
	    (pure-candidate-list-p lst) ;; it is like (2 (blue 3) 5 7 8).
	    (>= (length lst) 2)		;; 2024-03-16
	    (pencil-mark)
	    )
	   ;; pencil mark形式で表示するようにデータを変換。
           (setf lst (pencil-mark-list lst)) ;; (2 (blue 5) 7) ==> (0 2 0 0 (blue 5) 0 7 0 0)
           )
          ) ;; end cond

        ;; 表示用配列の作成。
        ;;
        ;; 9x9サイズのナンプレであれば,1マス当たり1〜9の9個(3x3)の候補数字を表示出来るようにする。
        ;; 従って(3x3)が(9x9)ある2次元配列[p-board]内に候補数字を配置する。"p" for pseudo.
        ;;
        ;; #=======================================================================#
        ;; # 1 2 . | 1 . . | 1 . . # . . . | . . . | . 2 . # . 2 . | . 2 . | . 2 . #
        ;; # 4 5 6 | 4 . 6 | 4 . 6 # . 7 . | . 3 . | 4 . 6 # . 5 6 | . . . | . . 6 #
        ;; # . . . | . . 9 | . . . # . . . | . . . | . . . # . . . | . 8 9 | . . 9 #
        ;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
        ;; # . 2 . | . . . | . . . # . . . | . 2 . | . 2 . # . . . | . . . | . 2 . #
        ;; # . 5 6 | . 3 . | . 7 . # . 8 . | . 5 . | . . 6 # . 1 . | . 4 . | . . 6 #
        ;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . 9 #
        ;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
        ;; # . 2 . | . . . | . . . # . . . | . 2 . | . . . # . 2 . | . . . | . 2 3 #
        ;; # 4 5 6 | . 8 . | 4 . 6 # . 9 . | 4 5 . | . 1 . # . 5 6 | . 7 . | . . 6 #
        ;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
        ;; #=======================#=======================#=======================#
        ;; # 1 . . | 1 . . | . . . # . . . | . 2 . | . . . # . . . | . 2 3 | 1 2 3 #
        ;; # 4 . . | 4 . . | . 5 . # . 6 . | 4 . . | . 8 . # . 9 . | . . . | . . . #
        ;; # 7 . . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
        ;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
        ;; # . . . | 1 . . | 1 . 3 # . . . | . . . | . 2 . # . 2 . | . 2 3 | . . . #
        ;; # . 9 . | 4 . 6 | 4 . 6 # . 5 . | . 7 . | 4 . . # . . 6 | . . . | . 8 . #
        ;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
        ;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
        ;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
        ;; # . . 6 | . . 6 | . 2 . # . 1 . | . 9 . | . 3 . # . 4 . | . 5 . | . . 6 #
        ;; # 7 8 . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
        ;; #=======================#=======================#=======================#
        ;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
        ;; # . 3 . | . 2 . | . 9 . # . 4 . | . 1 . | . 7 . # . 8 . | . 6 . | . 5 . #
        ;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
        ;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
        ;; # . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
        ;; # 4 . . | . 5 . | . 8 . # . 2 . | . 6 . | . 9 . # . 3 . | . 1 . | 4 . . #
        ;; # 7 . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
        ;; #-------+-------+-------#-------+-------+-------#-------+-------+-------#
        ;; # 1 . . | 1 . . | 1 . . # . . . | . . . | . . . # . 2 . | . 2 . | . 2 . #
        ;; # 4 . 6 | 4 . 6 | 4 . 6 # . 3 . | . 8 . | . 5 . # . . . | . . . | 4 . . #
        ;; # 7 . . | 7 . . | . . . # . . . | . . . | . . . # 7 . . | . . 9 | 7 . 9 #
        ;; #=======================================================================#
        (if (or (integerp lst) (stringp lst))
            (setf (aref p-board ;; then clause
                        (+ (floor *block-size* 2) (* i *block-size*))
                        (+ (floor *block-size* 2) (* j *block-size*))) lst)
            (dotimes (k (length lst)) ;; else clause
              (setf p (+ (* i *block-size*) (floor k *block-size*)))
              (setf q (+ (* j *block-size*) (mod k *block-size*)))
              (setf (aref p-board p q) (pop lst))
              ) ;; end dotimes
            )   ;; end if then else
        )       ;; end dotimes
      )         ;; end outer dotimes
    ;;(format t "~s~%" colored-brd)
    ;;(format t "~s~%" p-board)
    (reset-terminal-color)
    (print-outer-bar)
    (dotimes (i (* *block-size* *board-size*)) ;; 各セルに収める候補数字の横幅。
      (princ outer-ch)
      (dotimes (j (* *block-size* *board-size*)) ;; 各セルに収める候補数字の縦幅。
        (setf cell-row (floor i *block-size*)) ;; 候補数字表示用ボードでのセル単位の行番号。
        (setf cell-col (floor j *block-size*)) ;; 候補数字表示用ボードでのセル単位の列番号。

        (setf cell-color (aref colored-brd cell-row cell-col))
        (cond ;; セル全体を彩色する色指定があった場合の設定。
          ((identity cell-color)
           ;;(setf color (rest (assoc cell-color *parity-color-list*)))
           (setf color cell-color)
           (setf tmp (color-type)) ;; 現在のモードを保存。
           ;;(color-type 'xterm-background-color)
           (cond
             ((member tmp '(xterm-background-color xterm-text-color))
              (color-type 'xterm-background-color))
             ((member tmp '(ansi-background-color ansi-text-color))
              (color-type 'ansi-background-color))
             ) ;; end cond
           (cond
             ((and (= i (* cell-row *block-size*)) (= j (* cell-col *block-size*)))
              (set-terminal-color (eval color))) ;; ref. (print-color-sample)
             ((and (= i (+ (* cell-row *block-size*) 1)) (= j (* cell-col *block-size*)))
              (set-terminal-color (eval color)))
             ((and (= i (+ (* cell-row *block-size*) 2)) (= j (* cell-col *block-size*)))
              (set-terminal-color (eval color)))
             ) ;; end cond
           )   ;; end (identity cell-color) clause
          )    ;; end cond

        (if (zerop (mod j *block-size*)) (princ *space*))
        (setf p (aref p-board i j))
        (cond
          ((or
            (colored-candidate-p p) ;; p = ([color] [number])
            (conflict-color-p p))
           (cond
             ((>= (color-mode) 2) ;; 2 = 彩色対象候補数字をカラー出力。
              (cond ;; セル全体の彩色が設定されているときは候補数字情報のみ出力する。2024-01-25
                ((identity cell-color)
                 (format t fmt (second p))
                 (princ *space*)
                 )
                (t
                 (set-terminal-color (eval (first p))) ;; 表示色を設定する。
                 (format t fmt (second p))
                 (restore-terminal-color) ;; 表示色を元に戻す。
                 (princ *space*)
                 )
                )
              )
             ((= (color-mode) 1) ;; 1 = 彩色対象候補数字をカラーの短縮色名で出力。
              (cond ;; セル全体の彩色が設定されているときは候補数字情報のみ出力する。2024-01-25
                ((identity cell-color)
                 (setf chr (short-color-name (first p))) ;; 短縮表記の色名
                 (format t fmt chr)
                 (princ *space*)
                 )
                (t
                 (setf chr (short-color-name (first p))) ;; 短縮表記の色名
                 (set-terminal-color (eval (first p)))
                 (format t fmt chr)
                 (restore-terminal-color)
                 (princ *space*)
                 )
                )
              )
             ((= (color-mode) 0) ;; 0 = 彩色対象候補数字を短縮色名で出力（完全モノクロ）。
              (setf chr (short-color-name (first p))) ;; 短縮表記の色名
              (format t fmt chr)
              (princ *space*) )
             (t (error "print-normal-sub: No such color level(~s)." (color-mode)))))
          ((stringp p)
           (format t fmt2 p)
           (princ *space*) )
          ((characterp p) ;; 空白文字か短縮色名。
           (format t fmt2 p)
           (princ *space*) )
          ((zerop p) ;; 該当する候補数字が存在しないことを表す値。
           (putc *spc* wd)
           (princ *space*) )
          ((minusp p) ;; 確定値
           (format t fmt (- p))
           (princ *space*) )
          (t (format t fmt p) ;; 通常の候補数字。
             (princ *space*) ))

        (when (identity cell-color) ;; セル全体に対する彩色指定だった場合の彩色終了処理。
          (cond
            ((and (= i (* cell-row *block-size*)) (= j (+ (* cell-col *block-size*) 2)))
             (restore-terminal-color))
            ((and (= i (+ (* cell-row *block-size*) 1)) (= j (+ (* cell-col *block-size*) 2)))
             (restore-terminal-color))
            ((and (= i (+ (* cell-row *block-size*) 2)) (= j (+ (* cell-col *block-size*) 2)))
             (restore-terminal-color)) )
          (color-type tmp) ;; 保存しておいたモードに復帰。
          )

        (cond
          ((= (1+ i) (1+ j) (* *block-size* *board-size*))
           (princ outer-ch))
          ((= (mod j *board-size*) (1- *board-size*))
           (princ block-corner-ch) )
          ((= (mod j *block-size*) (1- *block-size*))
           (princ sep-ch) ) ) )
      (terpri nil)
      (cond
        ((= (1+ i) (* *block-size* *board-size*))
         (print-outer-bar))
        ((= (mod i *board-size*) (1- *board-size*))
         (print-bold-bar))
        ((= (mod i *block-size*) (1- *block-size*))
         (print-mid-bar))))
    (reset-terminal-color)
    (pause-if (pause))
    (finish-output)
    (return-from print-normal-sub t)
    ) ;; end let
  ) ;; end print-normal-sub

;;;
;;;
(defun set-colored-cell (board cell-addr color)
"指定されたセル全体を指定された色で表示するように設定する。
  
実際にカラーで表示するためにはxterm 256 colorに対応した端末ソフトと
  (color-mode n) ;; n >= 1
  (show-color-board t)
という、端末がカラー表示に対応＆カラー表示を選択していることをNumberPlace.lispに教えるための設定が必要。

ボード[board]のセルアドレス[cell-addr]全体を色[color]で彩色する。
  Ex. (set-colored-cell board '(2 3) 'blue)  ;;ボード左上を0行0列として指定する。

指定できる色は[*parity-color-list*]で定義されている
  red,green,blue,cyan,magenta,yellow,gray,black (RGB+CMYK)
各色の記号名に対応する具体的な色はプログラム中の *xcolor-red*,*xcolor-green*,...,*xcolor-black*
で定義している。定義に使用している数値と色味の対応は[(print-color-sample)]関数で表示できる。

[cell内容]        ::= [nil] | [candidate] | ([color] [candidate]) ;
[candidate] ::= [number] | ([color] [number]) | ([candidate]...) ;"
  (let (brd row col cell)
    (debug-write "set-colored-cell" (format nil "set-colored-cell-1 cell-addr=~a, color=~a" cell-addr color))
    (setf brd (new-board board))
    (setf row (first cell-addr) col (second cell-addr))
    (setf cell (aref brd row col))

    (cond ;; [cell-addr]の内容[cell]に応じた置き換えを行う。
      ((null cell) ;; セルの内容が空。
       (do-nothing)
       )
      ((integerp cell) ;; 単独の数値(確定値)。
       (setf (aref brd row col) (list color cell))
       )
      ((colored-candidate-p cell) ;; 色指定された候補数字 ([color] [number])
       (setf (aref brd row col) (list color cell))
       )
      ((pure-candidate-list-p cell) ;; 数字または色指定された数字の列からなるリスト。([candidate]...)
       (setf (aref brd row col) (cons color cell))
       )
      ((systems-colored-candidate-list-p cell) ;; セル全体に対する削除色または矛盾色の指定がある。
       (do-nothing)
       )
      ((users-colored-candidate-list-p cell) ;; セル全体に対する使用許可された色名の指定がある。
       (setf (aref brd row col) (cons color (rest cell))) ;; 新しく指定された色名に書き換える。
       )
      (t (error "候補数字を含むセルとして許されていない形式です。~a" cell))
      ) ;; end cond

    (debug-write "set-colored-cell" (format nil "set-colored-cell-2 brd=~a" brd))
    (if (<= (color-mode) 1)
        (setf brd (set-colored-all-candidates brd cell-addr color))
        (debug-write "set-colored-cell" (format nil "set-colored-all-candidates brd=~a" brd))
        ) ;; end if
    (return-from set-colored-cell brd)
    ) ;; end let
  ) ;; end set-colored-cell

(defun set-colored-cells (board colored-cell-def-list-list)
"複数のセルを指定された色で彩色する。表示は関数[print-normal]で行う。

[colored-cell-def-list-list] ::= (([color-name] [cell-addr]...)...) ;
[colored-cell-def-list] ::= ([color-name] [cell-addr]...) ;

(set-colored-cells [board] '((blue (4 2) (5 0)) (green (4 5) (7 5))))
  ==> r5c3,r6c1を[blue]に彩色し、r5c6,r8c6を[green]に彩色する。

実際にカラーで表示するためにはxterm 256 colorに対応した端末ソフトと
  (color-mode n) ;; n >= 1
  (show-color-board t)
という端末がカラー表示に対応し,カラー表示を選択していることをNumberPlace.lispに教えるための設定が必要。

指定できる色は[*parity-color-list*]で定義されている
  red,green,blue,cyan,magenta,yellow,gray,black (RGB+CMYK)
各色の記号名に対応する具体的な色はプログラム中の *xcolor-red*,*xcolor-green*,...,*xcolor-black*
または *ansi-red*, *ansi-green*, ... , *ansi-black* で定義している。*parity-color-list*に定義されている。
定義に使用している数値と色味の対応は[(print-color-sample)]関数で表示できる。"
  (let (brd color)
    (setf brd (new-board board))
    (dolist (colored-cell-def-list colored-cell-def-list-list)
      (setf color (first colored-cell-def-list))
      (dolist (cell-addr (rest colored-cell-def-list))
        (setf brd (set-colored-cell brd cell-addr color))
        )
      )
    (return-from set-colored-cells brd)
    ) ;; end let
  )

(defun set-colored-candidate (board cell-addr target color)
"盤面[brd]のセル[cell]内の候補数字[target]を[color]色に設定する。

3行4列に存在する候補数字7を[blue]で表示するように設定する。

(set-colored-candidate board '(2 3) 7 'blue)
    (1 3 4 7) ==> (1 3 4 (blue 7)) ;; セル (2 3) の内容が (1 3 4 7) の場合。

実際にカラーで表示するためにはxterm 256 colorに対応した端末ソフトと
  (color-mode n) ;; n >= 1
  (show-color-board t)
という端末がカラー表示に対応し,カラー表示を選択していることをNumberPlace.lispに教えるための設定が必要。

指定できる色は[*parity-color-list*]で定義されている
  red,green,blue,cyan,magenta,yellow,gray,black (RGB+CMYK)
各色の記号名に対応する具体的な色はプログラム中の *xcolor-red*,*xcolor-green*,...,*xcolor-black*
で定義している。定義に使用している数値と色味の対応は[(print-color-sample)]関数で表示できる。

指定した色名は対応付けられている内部名称に変換して設定している。

[cell内容]        ::= [nil] | [candidate] | ([color] [candidate]) ;
[candidate] ::= [number] | ([color] [number]) | ([candidate]...) ;

[cell内容]に対して
    [nil]                   ==>     何もしない。
    [number]                ==>     ([color] [candidate])   ;; [number] = [candidate]の場合。
    ([旧color] [number])   ==>     ([新color] [candidate]) ;; [number] = [candidate]の場合。
    ([candidate]...)        ==>     上記の[candidate]に対する処理を繰り返す。
    ([color] [candidate])   ==>     [candidate]に対して上記の処理を繰り返す。

 確定値に対する[set-colored-candidate]はセル全体への彩色となる。"
  (let (brd row col candidate-list)
    (setf brd (new-board board))
    (setf row (first cell-addr) col (second cell-addr))
    (setf candidate-list (aref brd row col))
    (cond
      ((null candidate-list)
       (do-nothing))
      ((integerp candidate-list)
       (setf (aref brd row col) (list color candidate-list))
       )
      ((candidate-list-p candidate-list)
       (debug-write "set-colored-candidate" (format nil "candidate-list=~a" candidate-list))
       (setf (aref brd row col) (candidate-mapping candidate-list target color))
       )
      (t
       (setf (aref brd row col) (candidate-mapping candidate-list target color))
       )
      ) ;; end cond
    (return-from set-colored-candidate brd)
    ) ;; end let
  )

(defun set-colored-candidates (board cell-addr target-list color)
"彩色対象候補数字をリストとして複数与えることが出来る。
[set-colored-candidate]関数に対して 関数名の末尾に\"s\"が付いていることに注意。"
  (let (brd)
    (setq brd (new-board board))
    (dolist (p target-list)
      (setq brd (set-colored-candidate brd cell-addr p color))
      ) ;; end dolist
    (return-from set-colored-candidates brd)
    ) ;; end let
  ) ;; end set-colored-candidates

(defun set-colored-all-candidates (board cell-addr color)
"盤面[board]のセル[cell-addr]内の全ての候補数字を候補数字単位で[color]に彩色する。"
  (let (brd candidate-list row col tmp-candidate-list color-name)
    (setf brd (new-board board))
    (setf row (first cell-addr) col (second cell-addr))
    (setf candidate-list (aref brd row col))
    (setf color-name nil)

    (if (not (pure-listp candidate-list)) (setf candidate-list (list candidate-list)))

    (debug-write "set-colored-all-candidates" (format nil "candidate-list=~a" candidate-list))
    (when (colored-candidate-list-p candidate-list)
      (setf color-name (pop candidate-list))
      )
    (debug-write "set-colored-all-candidates" (format nil "candidate-list=~a" candidate-list))

    (setf tmp-candidate-list candidate-list)

    (when (<= (color-mode) 1)
      (dolist (target candidate-list)
        (debug-write "set-colored-all-candidates"
                     (format nil "target=~a, tmp-candidate-list=~a" target tmp-candidate-list))
        (setf tmp-candidate-list (candidate-mapping tmp-candidate-list target color))
        ) ;; end dolist
      )   ;; end when

    (if color-name (setf tmp-candidate-list (cons color-name tmp-candidate-list)))
    (setf (aref brd row col) tmp-candidate-list)
    (return-from set-colored-all-candidates brd)
    ) ;; end let
  ) ;; end set-colored-all-candidates

(defun candidate-mapping (candidate-list target color)
"引数[candidates]の中の[target]を[color]に彩色する。

[cell内容]に対して
    [cell内容]    ::= ([color] [candidate]) | [candidate] ;
    [candidate]     ::= [number] | ([color] [number]) | [candidate]... ;

    ([color] [candidate])   ==>     ([color] [新candidate])
    [number]                ==>     ([color] [target])   ;; [number] = [target]の場合。
    ([旧color] [number])   ==>     ([新color] [target]) ;; [number] = [target]の場合。
    [candidate]...          ==>     上記の[candidate]に対する処理を繰り返す。"
  (let (result color-name tmp)
    (setf tmp nil)
    (setf color-name nil)

    (if (colored-candidate-list-p candidate-list) ;; セル全体に対する色指定がある。
      (setf color-name (pop candidate-list))
      )
    (if (colored-candidate-p target) (setf target (second target)))

    (setf result
          (cond
            ((or
              (null candidate-list)
              (integerp candidate-list)
              (colored-candidate-p candidate-list))
             (candidate-mapping-sub candidate-list target color)
             )
            ((pure-candidate-list-p candidate-list)
             (dolist (p candidate-list)
               (debug-write "candidate-mapping"
                            (format nil "p=~a, target=~a, color=~a, result=~a" p target color tmp))
               (push (candidate-mapping-sub p target color) tmp)
               ) ;; end dolist
             (sort tmp #'colored-lessp)
             ) ;; end (pure-candidate-list-p candidate-list)
            ) ;; end cond
          ) ;; end setf

    (if color-name (setf result (cons color-name result)))

    (return-from candidate-mapping result)
    ) ;; end let
  )

(defun candidate-mapping-sub (candidate target color)
  (let (result)
    (setf result
          (cond
            ((null candidate)
             nil)
            ((and ;; 候補数字[candidates]が単独数値で、対象数値[target]に等しい。
              (integerp candidate)
              (= candidate target))
             (list color candidate)
             )
            ((and ;; 候補数字[candidate]が単独の数値で、対象数値[target]とは異なる。
              (integerp candidate)
              (/= candidate target) )
             candidate
             )
            ((and ;; 候補数字[candidate]が([色名] [数値])の形式で[数値]が[target]と一致。
              (colored-candidate-p candidate)
              (= (second candidate) target))
             (list color target)
             )
            ((and ;; 候補数字[candidate]が([色名] [数値])の形式で[数値]が[target]と不一致。
              (colored-candidate-p candidate)
              (/= (second candidate) target))
             candidate
             )
            (t (error "候補数字フォーマットとして許されない形式です。") )
            ) ;; end cond
          ) ;; end setf
    (return-from candidate-mapping-sub result)
    ) ;; end let
  )

(defun colored-cell-p (brd cell-addr)
"指定されたセル[cell-addr]がセル全体に対して彩色設定されているか否かを返す。"
  (let (candidates)
    (setf candidates (aref brd (first cell-addr) (second cell-addr)))
    (return-from colored-cell-p (colored-candidate-list-p candidates))
    )   ;; end let
  )

(defun candidate-list-p (lst)
"色指定されている、いないかに関わらず定義に従った候補数字のリストか否かを返す。"
  (or
   (pure-candidate-list-p lst)
   (colored-candidate-list-p lst)
   )
  )
(defun colored-candidate-list-p (lst)
"セル全体が色指定されたセルか否かを返す。定義本体。"
  (or
   (users-colored-candidate-list-p lst)
   (systems-colored-candidate-list-p lst)
   )
  )

(defun users-colored-candidate-list-p (lst)
"セル全体が色指定されたセルか否かを返す。"
  (if (not (pure-listp lst)) (return-from users-colored-candidate-list-p nil))
  (if (not (member (first lst) *authorized-color-list*))
      (return-from users-colored-candidate-list-p nil))
  (dolist (p (rest lst))
    (if (not (or (integerp p) (colored-candidate-p p)))
        (return-from users-colored-candidate-list-p nil))
    ) ;; end dolist
  (return-from users-colored-candidate-list-p t)
  )

(defun systems-colored-candidate-list-p (lst)
"NumberPlace.lispがシステム的に独占使用するセル全体が色指定のあるセルか否かを返す。"
  (if (not (pure-listp lst)) (return-from systems-colored-candidate-list-p nil))
  (if (not (member (first lst) '(*elimination-color* *conflict-color*)))
      (return-from systems-colored-candidate-list-p nil))
  (dolist (p (rest lst))
    (if (not (or (integerp p) (colored-candidate-p p)))
        (return-from systems-colored-candidate-list-p nil))
    ) ;; end dolist
  (return-from systems-colored-candidate-list-p t)
  )

(defun pure-candidate-list-p (lst)
"[数字]または[色指定付き候補数字]のいずれか、または両方からなるリストか否かを返す。"
  (if (null lst) (return-from pure-candidate-list-p nil)) ;; [nil]なら[nil]

  (if (or
       (integerp lst)
       (colored-candidate-p lst)
       )
      (return-from pure-candidate-list-p t)) ;; [number]または([color] [number])なら[t]

  (dolist (p lst)
    (if (not (or (integerp p) (colored-candidate-p p)))
        (return-from pure-candidate-list-p nil))
    ) ;; end dolist
  (return-from pure-candidate-list-p t)
  )

(defun paint-block (board blk-num color)
"ボード[board]のブロック番号[blk-num]全体を[color]色に彩色する。
返される結果のボードを (print-normal brd) とすれば彩色されたボードが表示される。
表示は (color-mode) の設定に従う。"
  (let (brd)
    (setf brd (new-board board))
    (setf brd (set-colored-cells brd (list (append (list color) (same-block-cells-for-block blk-num)))))
    (return-from paint-block brd)
    ) ;; end let
  ) ;; end paint-block

(defun paint-row (board row-num color)
"ボード[board]の行番号[row-num]で指定された行全体を[color]色に彩色する。"
  (let (brd)
    (setf brd (new-board board))
    (setf brd (set-colored-cells brd (list (append (list color) (same-row-cells-for-row row-num)))))
    (return-from paint-row brd)
    ) ;; end let
  )

(defun paint-col (board col-num color)
"ボード[board]の列番号[col-num]で指定された行全体を[color]色に彩色する。"
  (let (brd)
    (setf brd (new-board board))
    (setf brd (set-colored-cells brd (list (append (list color) (same-col-cells-for-col col-num)))))
    (return-from paint-col brd)
    ) ;; end let
  )

(defun paint-house (board cell color)
"ボード[board]のセル・アドレス[cell]が含まれるハウス全体を[color]色に彩色する。"
  (let (brd)
    (setf brd (new-board board))
    (setf brd (set-colored-cells brd (list (append (list color) (same-house-cells cell)))))
    (return-from paint-house brd)
    ) ;; end let
  )

(defun paint-cells (board cell-list color)
"引数[cell-list]で指定されたセル全てを[color]色に彩色する。
(paint-cells [board] (parse-cell-expression [cell-expression] [brd]) color)が最も汎用的。
[cell-expression]は(describe 'parse-cell-expression)を参照。
"
  (let (brd)
    (setf brd (new-board board))
    (setf brd (set-colored-cells brd (list (append (list color) cell-list))))
    (return-from paint-cells brd)
    )
  )

(defun pencil-mark-list (lst)
"候補リストをpencil-mark形式で表示できるように変換する。
(2 5 7) ==> (0 2 0 0 5 0 7 0 0)
(2 (blue 5) 7) ==> (0 2 0 0 (blue 5) 0 7 0 0)"
  (let ((digit *np-digit*) result color-name)
    (setf result nil)
    (setf color-name nil)
    (if (colored-candidate-list-p lst) (setf color-name (pop lst)))
    (if (integerp lst) (setf lst (list lst)))
    (loop
      (if (null digit) (return))
      (cond
        ((same-candidate-p (first lst) (first digit)) ;; 2024-01-24l      (push (pop lst) result))
         (push (pop lst) result)
         )
        (t (push 0 result))
        )
      (pop digit)
      ) ;; end loop
    (setf result (reverse result))
    (if color-name (setf result (cons color-name result)))
    (return-from pencil-mark-list result)
    )
  )

(defun true-color (color-name)
  (let (result)
    (cond
      ((setf result (assoc color-name *parity-color-list*))
       (rest result)
       )
      ((member color-name (mapcar #'rest *parity-color-list*))
       color-name
       )
      ((member color-name '(*elimination-color* *conflict-color*))
       color-name
       )
      ((setf result (assoc color-name *short-colors*))
       (rest result)
       )
      (t (error "登録されていない色名を使おうとしています。~a" color-name))
      ) ;; end cond
    )
  )

(defun set-terminal-color (color)
  "端末に対する以後の出力を指定された色で行う。
see ref. http://en.wikipedia.org/wiki/ANSI_escape_code"
  ;;(print-color-string:save-terminal-color color)
  ;;(print-color-string:set-terminal-env (print-color-string:current-terminal-type) color
	;;			       (print-color-string:color-mode-level))
  (print-color-string:set-terminal-env (print-color-string:current-terminal-type) color)
  (cond
    ((string-equal-by-name-p (print-color-string:current-terminal-type) 'xterm-text-color)
     (setf *parity-colors* *xterm-parity-colors*)
     ;;(set-xterm-text-color color)
     )
    ((string-equal-by-name-p (print-color-string:current-terminal-type) 'xterm-background-color)
     (setf *parity-colors* *xterm-parity-colors*)
     ;;(set-xterm-background-color color)
     )
    ((string-equal-by-name-p (print-color-string:current-terminal-type) 'ansi-text-color)
     (setf *parity-colors* *ansi-parity-colors*)
     ;;(set-ansi-text-color color)
     )
    ((string-equal-by-name-p (print-color-string:current-terminal-type) 'ansi-background-color)
     (setf *parity-colors* *ansi-parity-colors*)
     ;;(ansi-background-color color)
     )
    (t
     (error "*color-type*に不正な値が設定されています。")
     )
    )
  ;;(push color *last-color-type*)
  )

(defun restore-terminal-color()
"端末に対する以後の出力を前回の端末設定色に戻す。"
  (when (>= (color-mode) 1)
    (pop *last-color-type*)
    (cond
      ((null (first *last-color-type*))
       (reset-all-attributes))
      (t (set-terminal-color (pop *last-color-type*)))))
  (return-from restore-terminal-color t))

(defun reset-terminal-color()
"端末に対する以後の出力を端末既定色に設定する。"
  (when (>= (color-mode) 1)
    (setf *last-color-type* nil)
    (reset-all-attributes))
  (return-from reset-terminal-color t))

#|
(defun put-color-string (color str &optional (color-kind nil sw) &key ((:terpri use-terpri) nil))
"[color]で指定した色で文字列[str]を表示する。
[color]は[*parity-color-list*]と[*short-colors*]に登録された名前を許す。
[color-kind]に許される引数は['background-color]と['text-color]のみ。
['background-color]は背景塗りつぶし、['text-color]は彩色された文字。
文字列の直後に改行を印字する場合は「:terpri t」を追加する。
「:terpri nil」なら改行を行わない。「:terpri nil」がデフォルト。"
  (let (color-code saved-color-type)

    (when (null (show-color-board)) ;; 解説ボードにカラー表示を行わない→モノクロで出力。2024-03-19
      (write str :escape nil)
      (finish-output)
      (return-from put-color-string str)
      ) ;; end when

    (if (null sw) (setf color-kind 'background-color)) ;; default.
    (when (not (member color-kind '(background-color text-color)))
      (format t "~a" str)
      (return-from put-color-string nil)
      ) ;; end when
    (when (not (member color (mapcar 'car *parity-color-list*)))
      (format t "~a" str)
      (return-from put-color-string nil)
      ) ;; end when
    (setf saved-color-type (color-type))
    (cond
      ((and
        (equal color-kind 'background-color)
        (member (color-type) '(xterm-background-color xterm-text-color))
        )
       (color-type 'xterm-background-color)
       )
      ((and
        (equal color-kind 'background-color)
        (member (color-type) '(ansi-background-color ansi-text-color))
        )
       (color-type 'ansi-background-color)
       )
      ((and
        (equal color-kind 'text-color)
        (member (color-type) '(xterm-background-color xterm-text-color))
        )
       (color-type 'xterm-text-color)
       )
      ((and
        (equal color-kind 'text-color)
        (member (color-type) '(ansi-background-color ansi-text-color))
        )
       (color-type 'ansi-text-color)
       )
      ) ;; end cond

    (cond
      ((assoc color *parity-color-list*)
       (setf color-code (eval (rest (assoc color *parity-color-list*))))
       )
      ((assoc color *short-colors*)
       (setf color-code (eval (first (assoc color *short-colors*))))
       )
      ) ;; end cond
    (set-terminal-color color-code)
    (write str :escape nil)
    (finish-output)
    (restore-terminal-color)
    (color-type saved-color-type)
    (if use-terpri (terpri))
    (return-from put-color-string str)
    ) ;; end let
  ) ;; end put-color-string
|#

#|
(defun put-bold-string (color str)
"指定された文字列を[color]色の太字で出力する。"
  (let (saved-color-type color-code)
    (when (not (member color (mapcar 'car *ansi-parity-color-list*)))
      (write str :escape nil)
      (return-from put-bold-string nil)
      ) ;; end when
    (setf saved-color-type (color-type))
    (color-type 'ansi-text-color)
    (setf color-code (eval (rest (assoc color *parity-color-list*)))) ;; 設定されたカラー・コードを得る。
    (set-ansi-text-color color-code :bold t) ;; [t] for bold mode.
    ;;(erase-in-line 0)
    (write str :escape nil)
    (reset-all-attributes)
    (color-type saved-color-type) ;; restore color-type.
    (return-from put-bold-string str)
    ) ;; end let
  ) ;; end put-bold-string
|#

(defun put-bold-string (color str)
  (print-colored-string color str :bold t)
  )

(defun color-type (&optional (mode nil sw))
"端末のカラー設定を指定する。指定できるのは
'xterm-background-color(='xterm)
'xterm-text-color
'ansi-background-color(='ansi)
'ansi-text-color
"
  (cond
    ((or
      (null sw)
      (null mode))
     *color-type*)
    ((member mode '(xterm xterm-background-color)) ;; [xterm] for abbreviation of [xterm-background-color].
     (setf *parity-color-list* *xterm-parity-color-list*)
     (setf *parity-colors* *xterm-parity-colors*)
     (setf *short-colors* *xterm-short-colors*)
     (setf *color-type* 'xterm-background-color))
    ((equal mode 'xterm-text-color)
     (setf *parity-color-list* *xterm-parity-color-list*)
     (setf *parity-colors* *xterm-parity-colors*)
     (setf *short-colors* *xterm-short-colors*)
     (setf *color-type* 'xterm-text-color))
    ((member mode '(ansi ansi-background-color)) ;; [ansi] for abbreviation of [ansi-background-color].
     (setf *parity-color-list* *ansi-parity-color-list*)
     (setf *parity-colors* *ansi-parity-colors*)
     (setf *short-colors* *ansi-short-colors*)
     (setf *color-type* 'ansi-background-color))
    ((equal mode 'ansi-text-color)
     (setf *parity-color-list* *ansi-parity-color-list*)
     (setf *parity-colors* *ansi-parity-colors*)
     (setf *short-colors* *ansi-short-colors*)
     (setf *color-type* 'ansi-text-color))
    (t (error "color-type:引数に不正な値が設定されています。"))))

#|
(defun xterm-text-color (color)
"X terminalカラー設定で文字を指定された[color]で表示するためのエスケープ・シーケンスを出力する。
以後、設定が変更されるまで、ここで指定された文字色での出力となる。"
  (when (>= (color-mode) 1)
    (write ESC :escape nil)
    (write #\[ :escape nil)
    (write 38 :escape nil)
    (write #\; :escape nil)
    (write 5 :escape nil)
    (write #\; :escape nil)
    (write color :escape nil)
    (write #\m :escape nil)
    )
  (return-from xterm-text-color t))

(defun xterm-background-color (color)
"X terminalカラー設定で文字背景を指定された[color]で表示するためのエスケープ・シーケンスを出力する。
以後、設定が変更されるまで、ここで指定された背景色での出力となる。"
  (when (>= (color-mode) 1)
    (write ESC :escape nil)
    (write #\[ :escape nil)
    (write 48 :escape nil)
    (write #\; :escape nil)
    (write 5 :escape nil)
    (write #\; :escape nil)
    (write color :escape nil)
    (write #\m :escape nil)
    )
  (return-from xterm-background-color t))

(defun ansi-text-color (color &key ((:bold bold-print) nil))
"ANSIで定義された文字を[color]で表示するためのエスケープ・シーケンスを出力する。
以後、設定が変更されるまで、ここで指定された文字色での出力となる。"
  (when (>= (color-mode) 1)
    (write ESC :escape nil)
    (write #\[ :escape nil)
    (when (identity bold-print) ;;強調表示(bold)
      (write 1 :escape nil)
      (write #\; :escape nil)
      )
    (write (+ color 30) :escape nil) ;; 30-37 selected the foreground color.
    (write #\m :escape nil)
    )
  (return-from ansi-text-color t))

(defun ansi-background-color (color)
"ANSIで定義された背景色[color]で表示するためのエスケープ・シーケンスを出力する。
以後、設定が変更されるまで、ここで指定された背景色での出力となる。"
  (when (>= (color-mode) 1)
    (write ESC :escape nil)
    (write #\[ :escape nil)
    (write (+ color 40) :escape nil) ;; 40-47 selected the background color.
    (write #\m :escape nil)
    )
  (return-from ansi-background-color t))

(defun reset-all-attributes ()
"文字色および背景色の設定をリセットする。xterm系とansi系で共通。"
  (when (>= (color-mode) 1)
    (write ESC :escape nil)
    (write #\[ :escape nil)
    ;;(write 0 :escape nil)
    (write #\m :escape nil)
    )
  (return-from reset-all-attributes t)
  )
|#

;; if pos=0 clear from cursor to end of the line.
;; if pos=1 clear from cursor to beginning of the line.
;; if pos=2 clear entire line.
(defun erase-in-line (&optional (pos 0))
  (write ESC :escape nil)
  (write #\[ :escape nil)
  (write pos :escape nil)
  (write #\K :escape nil)
  )

(defun print-color-sample ()
"関数[color-type]の設定に従って、色コードと色見本を表示する。"
  (case (color-type)
    ((set-xterm-background-color xterm-text-color)
     (print-xcolor-sample))
    ((set-ansi-background-color ansi-text-color)
     (print-ansi-color-sample))
    (otherwise (do-nothing))))

(defun print-xcolor-sample ()
"xterm 256カラーの文字コードと色見本を表示する。"
  (format t "xterm = 256 colors~%")
  (format t "~5a" *space*)
  (format t "text-color")
  (format t "~7a" *space*)
  (format t "background-color~%")
  (dotimes (color 256)
    (format t "~3d: " color)
    (set-xterm-text-color color)
    (format t "012345679")
    (reset-terminal-color)
    (format t "~8a" *space*)
    (set-xterm-background-color color)
    (format t "012345679")
    (reset-terminal-color)
    (terpri)
    )
  (finish-output)
  (return-from print-xcolor-sample t) )

(defun print-ansi-color-sample ()
"ANSIで定義された8色の文字コードと色見本を表示する。"
  (format t "ansi = 8 colors~%")
  (format t "~5a" *space*)
  (format t "text-color")
  (format t "~7a" *space*)
  (format t "background-color~%")
  (dotimes (color 8)
    (format t "~3d: " color)
    (set-ansi-text-color color)
    (format t "012345679")
    (reset-terminal-color)
    (format t "~8a" *space*)
    (set-ansi-background-color color)
    (format t "012345679")
    (reset-terminal-color)
    (terpri)
    )
  (finish-output)
  (return-from print-ansi-color-sample t) )

(defun set-parity-color (num color-code short-name &optional (color-name nil))
"Advanced Coloringで使用する色を定義する関数。
  [num]        ::= [*parity-colors*]の[num]番目の要素として定義する。
  [color-code] ::= 使用したい色のコード番号。(print-color-sample)を実行すると参照できる。
  [short-name] ::= 色名を表す1文字の名前。Advanced Coloringの解説盤面内で使用する。
                   文字列を指定した場合は先頭文字が指定されたものとして扱う。
  [color-name] ::= プログラム内部で使用するパリティ色の名前を設定する。"
  (when (null color-name)
    (case num
      (1 (setf color-name '*color-1*))
      (2 (setf color-name '*color-2*))
      (otherwise (error "set-parity-color: 第1引数は [1]か[2]だけが許されます。"))))
  (setf (symbol-value color-name) color-code)
  (cond
    ((characterp short-name)
      (do-nothing))
    ((and (stringp short-name) (>= (length short-name) 1))
      (setf short-name (char short-name 0)))
    (t (error "set-parity-color: 第4引数は文字型または文字列型だけが許されます。")))
  (cond
    ((null (assoc color-name *short-colors*))
      (setf *short-colors* (acons color-name short-name *short-colors*)))
    (t (rplacd (assoc color-name *short-colors*) short-name)))
  (cond
    ((and (= num 1) (member *color-type* '(xterm-background-color xterm-text-color))) 
     (setf *xterm-parity-colors* (cons color-name (rest *xterm-parity-colors*)))
     (setf *parity-colors* *xterm-parity-colors*))
    ((and (= num 1) (member *color-type* '(ansi-background-color ansi-text-color))) 
     (setf *ansi-parity-colors* (cons color-name (rest *ansi-parity-colors*)))
     (setf *parity-colors* *ansi-parity-colors*))
    ((and (= num 2) (member *color-type* '(xterm-background-color xterm-text-color))) 
     (setf *xterm-parity-colors* (cons (first *xterm-parity-colors*) (list color-name)))
     (setf *parity-colors* *xterm-parity-colors*))
    ((and (= num 2) (member *color-type* '(set-ansi-background-color ansi-text-color))) 
     (setf *ansi-parity-colors* (cons (first *ansi-parity-colors*) (list color-name)))
     (setf *parity-colors* *ansi-parity-colors*))
    (t (error "set-parity-color:第1引数は[1]か[2]だけが許されます。"))
    )
  (format t "~d番目のパリティ色を" num)
  (set-terminal-color (eval color-name))
  (format t "~s (~c)" color-name short-name)
  (reset-terminal-color)
  (format t "に設定しました。")
  (return-from set-parity-color t))

(defun reset-parity-color ()
"関数[set-parity-color]で設定した設定をリセットする。"
  (case *color-type*
    ((set-xterm-background-color xterm-text-color)
     (setf *xterm-parity-colors* *xterm-original-parity-colors*)
     (setf *parity-colors* *xterm-parity-colors*))
    ((set-ansi-background-color ansi-text-color)
     (setf *ansi-parity-colors* *ansi-original-parity-colors*)
     (setf *parity-colors* *ansi-parity-colors*))))

(defun set-parity-color-1 (color-code short-name)
  (set-parity-color 1 color-code short-name '*color-1*))

(defun set-parity-color-2 (color-code short-name)
  (set-parity-color 2 color-code short-name '*color-2*))

(defun set-parity-1 (&optional (color-symbol-name nil))
  (let (symbol-name selectable-colors)
    (setf selectable-colors (assoc color-symbol-name *parity-color-list*))
    (cond
      ((null color-symbol-name)
       (print-symbol-colors 1))
      ((identity selectable-colors)
       (setf symbol-name (cdr selectable-colors))
       (when (equal symbol-name (rest *parity-colors*))
         (format t "重複するパリティ色は許されません。異なる色名を選択して下さい。")
         (print-symbol-colors 1)
         (return-from set-parity-1 nil) )
       ;;(setf *parity-colors* (cons symbol-name (rest *parity-colors*))))
       (case *color-type*
         ((set-xterm-background-color xterm-text-color)
          (setf *xterm-parity-colors* (cons symbol-name (rest *xterm-parity-colors*)))
          (setf *parity-colors* *xterm-parity-colors*)
          )
         ((set-ansi-background-color ansi-text-color)
          (setf *ansi-parity-colors* (cons symbol-name (rest *ansi-parity-colors*)))
          (setf *parity-colors* *ansi-parity-colors*)
          )
         )
       )
      (t (set-parity-1 nil)))
    (return-from set-parity-1 t)))

(defun set-parity-2 (&optional (color-symbol-name nil))
  (let (symbol-name selectable-colors)
    (setf selectable-colors (assoc color-symbol-name *parity-color-list*))
    (cond
      ((null color-symbol-name)
       (print-symbol-colors 2))
      ((identity selectable-colors)
       (setf symbol-name (cdr selectable-colors))
       (when (equal (first *parity-colors*) symbol-name)
         (format t "重複するパリティ色は許されません。異なる色名を選択して下さい。")
         (print-symbol-colors 2)
         (return-from set-parity-2 nil) )
       ;;(setf *parity-colors* (cons (first *parity-colors*) (list symbol-name)))
       (case *color-type*
         ((set-xterm-background-color xterm-text-color)
          (setf *xterm-parity-colors* (cons (first *xterm-parity-colors*) (list symbol-name)))
          (setf *parity-colors* *xterm-parity-colors*)
          )
         ((set-ansi-background-color ansi-text-color)
          (setf *ansi-parity-colors* (cons (first *ansi-parity-colors*) (list symbol-name)))
          (setf *parity-colors* *ansi-parity-colors*)
          )
         )
       )
      (t (set-parity-1 nil)))
    (return-from set-parity-2 t)))

(defun set-parity (&optional (color-1 nil) (color-2 nil))
  (cond
    ((and (null color-1) (null color-2))
      (print-symbol-colors 0))
    ((null color-1)
      (set-parity-2 color-2))
    ((null color-2)
      (set-parity-1 color-1))
    (t (set-parity-1 color-1)
      (set-parity-2 color-2)))
  (return-from set-parity t))

(defun print-symbol-colors (&optional (num 0) (code nil))
  (current-parity-colors)
  (format t "指定可能な色名は次のとおりです。")
  (cond
    ((zerop num)
     (format t "(set-parity \'green \'blue)のように指定します。~%"))
    ((or (= num 1) (= num 2))
     (format t "(set-parity-~d \'yellow)のように指定します。~%" num))
    (t (do-nothing)))
  (print-current-colors code)
  (return-from print-symbol-colors t))

(defun print-current-colors (&optional (code nil))
  (let (p q)
    (dolist (colors *parity-color-list*)
      (setf p (car colors))
      (setf q (cdr colors))
      (set-terminal-color (eval q))
      (format t "~s" p)
      (if (identity code) (format t "(~d)" (eval q)))
      (reset-terminal-color)
      (terpri))
    (return-from print-current-colors t)))

(defun current-parity-colors ()
  (let (code-1 code-2 short-1 short-2 color-1 color-2)
    (setf color-1 (first *parity-colors*))
    (setf short-1 (cdr (assoc color-1 *short-colors*)))
    (setf code-1 (eval color-1))
    (setf color-2 (second *parity-colors*))
    (setf short-2 (cdr (assoc color-2 *short-colors*)))
    (setf code-2 (eval color-2))
    (format t "現在の第1パリティ色は")
    (finish-output)
    (set-terminal-color code-1)
    (format t "~s" color-1)
    (reset-terminal-color)
    (format t " 短縮色名は")
    (finish-output)
    (set-terminal-color code-1)
    (format t "~c" short-1)
    (reset-terminal-color)
    ;;(terpri)
    (format t ", 第2パリティ色は")
    (finish-output)
    (set-terminal-color code-2)
    (format t "~s" color-2)
    (reset-terminal-color)
    (format t " 短縮色名は")
    (finish-output)
    (set-terminal-color code-2)
    (format t "~c" short-2)
    (reset-terminal-color)
    (format t "です。")
    (finish-output)
    ;;(terpri)
    (return-from current-parity-colors t)))

(defun internal-color-name (color)
"与えられた色名[color]をプログラム内部で使用している色名に変換して返す。
  ex. (internal-color-name 'blue)          ==> *xcolor-blue*
      (internal-color-name '*xcolor-blue*) ==> *xcolor-blue*"
  (cond
    ((assoc color *short-colors*) color)
    (t (rest (assoc color *parity-color-list*)))))

(defun print-mini (&optional (val nil switch))
"ボードを小さなサイズで出力するかどうかを設定する。
nilなら通常サイズ。nil以外なら小さなサイズで出力する。
ただし引数にボード型データを与えると、そのボードを小さなサイズで出力する。"
  (let (w fmt tmp brd)
    (when (board-p val) (set-board-size (board-size val)))
    (setf w (width *board-size*))
    (setf fmt (format nil " ~~~d\,'0\d" w))
    (cond
      ((null switch) *print-mini*)
      ((board-p val)
       (board-print-counter (1+ (board-print-counter)))
       (setf brd (mini-board val))
       (dotimes (i *board-size*)
         (when (zerop (mod i *block-size*)) (print-mini-bar))
         (dotimes (j *board-size*)
           (setf tmp (aref brd i j))
           (cond
             ((zerop j) (princ "|"))
             ((zerop (mod j *block-size*)) (princ " |")))
           (cond
             ((integerp tmp) (format t fmt tmp))
             (t (princ " ")
                (putc tmp w))))
         (princ " |")
         (terpri))
       (print-mini-bar)
       (pause-if (pause)))
      (t (setf *print-mini* val)))))

(defun print-outer-bar ()
"ボードの一番上と一番下の境界を描く関数。"
  (print-bar "#" "=" "=" "="))

(defun print-bold-bar ()
"ボードのブロック境界を描く関数。"
  (print-bar "#" "=" "#" "="))

(defun print-mid-bar ()
"ボードのセル境界を描く関数。"
  (print-bar "#" "+" "#" "-"))

(defun print-bar (outer-ch cross-ch block-corner-ch line-ch)
"ボードの区分線を描く関数。
A---------B---------B---------C---------B---   --B---------A
[A]=outer-ch, [B]=cross-ch, [C]=block-corner-ch, [-]=line-ch"
  (let (wd len)
    (setf wd (width *board-size*))
    (setf len (1+ (* (+ wd 1) *block-size*)))
    (princ outer-ch)
    (dotimes (k *block-size*)
      (dotimes (i *block-size*)
        (putc line-ch len)
        (cond
          ((= (1+ k) (1+ i) *block-size*) (princ outer-ch))
          ((zerop (mod (1+ i) *block-size*)) (princ block-corner-ch))
          (t (princ cross-ch)))))
    (terpri)))

(defun print-mini-bar ()
  (let (len)
    (setf len (+ (* (1+ (width *board-size*)) *board-size*) (* *block-size* 2) 1))
    (setf len (/ (- len (1+ *block-size*)) *block-size*))
    (princ "+")
    (dotimes (i *block-size*)
      (putc "-" len)
      (princ "+"))
    (terpri)))

(defun width (num)
"0..numまでの10進数を表現するのに必要な桁数を返す。"
  (let ((i 0))
    (setf num (abs num))
    (loop
       (incf i)
       (setf num (floor num 10))
       (when (zerop num) (return i)))))

(defun putc (c n)
  (dotimes (i n) (princ c)))

(defun mini-board (brd)
"小さなボードの内容を表現するデータを返す。
[数字]は確定値。
[-]は空欄のマス（初期状態）。
[=]は2コの候補を持つマス。
[+]は3コ以上の候補を持つマス。"
  (let (board tmp)
    (setf board (new-board brd))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf tmp (aref brd i j))
        (cond
          ((null tmp) (setf (aref board i j) '\-))
          ((eq tmp t) (setf (aref board i j) '\*))
          ((and (integerp tmp) (zerop tmp)) (setf (aref board i j) '\-))
          ((not (listp tmp)) (setf (aref board i j) (aref brd i j)))
          ((= (length tmp) 2) (setf (aref board i j) '\=))
          (t (setf (aref board i j) '\+)))))
    (return-from mini-board board)))

(defun print-problem (board)
  (set-board-size (board-size board))
  (save-env)
  (if (board-p board) (print-board (listup-all-possibility board)))
  (restore-env))

(defun listup-all-possibility (board)
  (let ((brd nil) (tmp nil))
    (setf brd (new-board board))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf tmp (aref brd i j))
        (when (and (integerp tmp) (zerop tmp)) ;; [0]以外の数字は確定値。
          (setf (aref brd i j) *np-digit*))))
    (return-from listup-all-possibility brd)))

(defun pause-if (condition)
"引数で指定した条件が成立しているなら関数[pause]を実行する。"
  (cond
    ((identity condition)
     (do-pause))
    (t (do-nothing))))

(defun pause (&optional (num nil switch))
"ボードを設定回数表示するごとに一時停止するように指定する。
[nil]なら一時停止しない。"
  (cond
    ((and
      (null switch)
      (null *insert-pause*)) nil)
    ((and
      (null switch)
      (integerp *insert-pause*)
      (plusp *insert-pause*)
      (plusp (board-print-counter)) ) ;; 2023-12-27
     (zerop (mod (board-print-counter) *insert-pause*)))
    ((null num)
     (setf *insert-pause* nil))
    ((and
      (integerp num)
      (<= num 0))
     (setf *insert-pause* nil))
    ((and
      (integerp num)
      (plusp num))
     (setf *insert-pause* num))
    (t nil)))

(defun pause-number ()
  *insert-pause*)

(defun do-pause ()
"端末出力を一時停止してユーザの応答を待つ。
  N)ext     設定されている盤面分先に進む。
  S)ingle   盤面をひとつ出力したら一時停止するように設定を変更して進む。
  C)hange   盤面を次の入力で指定する数出力したら一時停止するよう設定を変更して進む。
  G)o       一時停止を解除して解法終了まですべてを出力する。"
  (let (ch)
    (format t "Pause(~d)...N)ext S)ingle C)hange G)o H)elp: " *insert-pause*)
    (finish-output)
    (setf ch (read-char))
    (clear-input)                       ;2文字目の#\newlineを消去。
    (case ch
      ((#\N #\n) (do-nothing))
      ((#\S #\s) (pause 1))
      ((#\G #\g) (pause nil))
      ((#\C #\c)
       (format t "Change to? ")
       (finish-output)
       (pause (read))
       (clear-input)
       (board-print-counter 0))
      ((#\H #\h)
       (print-pause-help)
       (do-pause))
      ((#\newline) (do-nothing))
      (otherwise (do-pause))) ))

(defun print-pause-help ()
  (format t "N)ext      設定されている盤面分先に進む。~%")
  (format t "S)ingle    盤面をひとつ出力したら一時停止するように設定を変更して進む。~%")
  (format t "C)hange    盤面を次の入力で指定する数出力したら一時停止するよう設定を変更して進む。~%")
  (format t "G)o       一時停止を解除して解法終了まで全てを出力する。~%")
  (format t "H)elp      このヘルプ・メッセージを表示。~%")
  (finish-output)
  (return-from print-pause-help t))

(defun select-explanation-level (&optional (ch nil)) (sel ch))

(defun sel (&optional (ch #\a sw))
  (when (or (null ch) (null sw))
    (format t "解説盤面の種類とAdvanced Coloring画面の組み合わせを選択します。~%")
    (format t "xterm互換端末ではD, 非互換端末ではAかBがお奨めです。~%")
    (terpri)
    (format t "A) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=モノクロ＆記号。~%")
    (format t "B) 表示=モノクロ, サイズ=標準。Advanced Coloring表示=モノクロ＆記号。~%")
    (format t "C) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=カラー  ＆記号。~%")
    (format t "D) 表示=カラー  , サイズ=標準。Advanced Coloring表示=カラー  ＆記号。~%")
    (format t "E) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=カラー  ＆数字。~%")
    (format t "F) 表示=カラー,   サイズ=標準。Advanced Coloring表示=カラー  ＆数字。~%")
    (terpri)
    (format t "A...F: ")
    (finish-output)
    (setf ch (read-char))
    (clear-input)                       ;2文字目の#\newlineを消去。
    )
  (case ch ;; 以下、盤面サイズの設定を忘れていたので修正。
    ((#\A #\a)
     (color-mode 0)
     (print-mini t)
     (show-color-board nil))
    ((#\B #\b)
     (color-mode 0)
     (print-normal t)
     (show-color-board t))
    ((#\C #\c)
     (color-mode 1)
     (print-mini t)
     (show-color-board nil))
    ((#\D #\d)
     (color-mode 1)
     (print-normal t)
     (show-color-board t))
    ((#\E #\e)
     (color-mode 2)
     (print-mini t)
     (show-color-board nil))
    ((#\F #\f)
     (color-mode 2)
     (print-normal t)
     (show-color-board t))
    (otherwise (sel)))
  (return-from sel ch))

;;; グリッド解析用配列を1行1列を起点とする配列として出力する。デバッグ用。
(defun print-grid (grid)
  (let (grid-for-print)
    (save-env)
    (pencil-mark nil)
    (setf grid-for-print (new-board grid))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (if (pure-listp (aref grid i j))
            (setf (aref grid-for-print i j) (mapcar '1+ (aref grid i j))))))
    (restore-env)
    (print-normal grid-for-print)))

(defun simple-numberplace (board)
"絞り込みによって確定できる候補を決定する。試行錯誤は行わない。
ユーザが呼び出す場合のインタフェース関数。"
  (let (p)
    (set-board-size (board-size board))
    (save-env)
    (setf p (simple-numberplace-kernel (listup-all-possibility board)))
    (restore-env)
    (return-from simple-numberplace p)))

(defun simple-numberplace-kernel (board)
"simple-numberplaceの本体。"
  (cond
    ((not (think-depth))
     (setf board (simple-numberplace-kernel-without-search board)))
    ((think-depth)
     (setf board (simple-numberplace-kernel-with-search board))))
  (return-from simple-numberplace-kernel board))

(defun simple-numberplace-kernel-without-search (board)
"使用可能な手筋として登録された手筋を登録された順序で適用することを繰り返す。"
  (let (brd)
    (setf brd (do-auto-trim (new-board board) (auto-trim-level)))
    (loop
       (method-applied nil)
       (dolist (i (permitted-methods))
         ;;(format t "手筋 = ~s~%" i)
         (setf brd (funcall i brd))
         (if (and (easy-method-first) (method-applied)) (return)) )
       (if (equal-board-p brd board) (return))
       (setf board (new-board brd))
       (force-output))
    (return-from simple-numberplace-kernel-without-search brd)))

(defun simple-numberplace-kernel-with-search (board)
  (let (p brd methods)
    (setf brd (new-board board))        ;make room.
    (loop
       (setf p (search-methods brd (think-depth) (permitted-methods)))
       (setf methods (second p))
       ;; ある手筋で手を進められなくても別の手筋では手を進められる可能性がある。
       (dolist (i methods)
         (setf brd (funcall i brd)))
       (if (equal-board-p brd board) (return))
       (setf board (new-board brd)) )
    (return-from simple-numberplace-kernel-with-search brd)))

(defun check-initial-pattern (board)
"初期盤面をチェックして確定値が16以下であれば探索を続けるか否かを確認する。
ユーザが探索続行を選択した場合は[t]を返し、探索中止を選択した場合は[nil]を返す。"
  (let (num cell ch result)
    (setf num 0 result t)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf cell (aref board i j))
        (if (and (integerp cell) (> cell 0)) (incf num))))
    (force-output)
    (cond
      ((zerop num)
       (format t "初期状態での確定値がありません。およそ54億7000万通りの解が存在します。~%"))
      ((<= num 16)
       (format t "初期状態での確定値が16以下です。解が一意に定まらない可能性があります。~%")))
    (when (<= num 16)
      (format t "このまま解の探索を続けますか(y/n)? ")
      (force-output)
      (setf ch (read-char))
      (clear-input)                     ;2文字目の#\newlineを消去。
      (case ch
        ((#\N #\n) (setf result nil))
        ((#\Y #\y) (setf result t))
        ((#\newline) (setf result nil))
        (otherwise (setf result nil))))
    (return-from check-initial-pattern result)))

(defun search-methods (board n &optional (method-list *all-methods*))
"[method-list]で指定された手筋の範囲で[n]手先まで読んで「最善」の手筋の組合せを返す。
「最善」とは、
・確定できるセル数が多い手。
・確定できるセル数が同じ時は、消去できる候補数字の数が多い手。
と定義する。

返す値は ((確定するセル数 未確定候補の総数) (使用する手筋のリスト) 適用結果のボード)"
  (let (brd result p q last-method)
    (save-env)
    (suppress-message)
    (setf p '(0 0))
    (setf last-method nil)
    (method-applied nil)
    (setf brd (new-board board))
    (dolist (methods (make-method-seq n method-list))
      (setf brd board)
      (dolist (i methods)
        (cond
          ((method-applied)
           (setf brd (funcall i brd))
           (method-applied nil))
          ((not (equal last-method i))
           (setf brd (funcall i brd))
           (method-applied nil))
          (t (method-applied nil))))
      (setf q (eval-board brd))
      (debug-write "search-methods" (format nil "~s ~s" q methods))
      (when (good-board-p q p)
        (setf p q)
        (setf result (list p methods brd))))
    (restore-env)
    (return-from search-methods result)))

(defun good-board-p (x y)
"ボードに対する評価(eval-boardの結果)同士を比較して[x]の方が[y]より良いなら[t]を返す。
そうでないなら[nil]を返す。"
  (equal x (compare-list x y)))

(defun compare-list (x y)
"ボードに対する評価(eval-boardの結果)同士を比較して「良い方」を返す。"
  (cond
    ((> (first x) (first y)) x)
    ((< (first x) (first y)) y)
    ((= (first x) (first y))
     (if (< (second x) (second y)) x y))))

(defun suppress-message ()
  (check-backtrack-point nil)
  (explanation-level 0)
  (print-check nil)
  (plot-level nil))

(defun repeated-permutation (n r)
"[0]から[n-1]の[n]コから、[r]コ重複を許して取り出す順列のリストを返す。
各順列は、[n]進数での[0]から[(n^r)-1]に1対1に対応する。したがって、
この数の[r]桁[n]進法での各桁のリストのリストを返せばよい。"
  (let (nrp result cell tmp)                            ;Number of Repeated Permutation.
    (setf result nil)
    (setf nrp (expt n r))
    (dotimes (i nrp)
      (setf tmp i)
      (setf cell nil)
      (dotimes (j r)
        (push (mod tmp n) cell)
        (setf tmp (floor tmp n)))
      (push cell result))
    (return-from repeated-permutation (reverse result))))

(defun make-method-seq (n &optional (method-list *all-methods*))
"[methods]で指定された手筋による[n]手先までの「読み筋」のリストを作成して返す。"
  (let (rplist method-alist)
    (setf method-alist nil)
    (setf rplist (repeated-permutation (length method-list) n))
    (dotimes (i (length method-list))
      (push (cons i (pop method-list)) method-alist))
    (return-from make-method-seq (sublis method-alist rplist))))

(defun eval-board (brd)
"ボード[brd]の状態を評価した値を返す。
ボード[brd]内の確定値の数と候補数字の数をリストにして返す。"
  (let (candidates determined tmp)
    (setf candidates 0 determined 0)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf tmp (aref brd i j))
        (cond
          ((and (integerp tmp) (zerop tmp))
           (incf candidates *board-size*))
          ((integerp tmp)
           (incf determined))
          ((pure-listp tmp)
           (incf candidates (length tmp))))))
    (return-from eval-board (list determined candidates))))

(defun do-trial-and-error (brd)
"試行錯誤によって解を探す。"
  (let (board p i j lst n-lst fmt strlen msg)
    (exec-count (1+ (exec-count)))
    (depth (1+ (depth)))
    (setf board (new-board brd))
    (setf n-lst (next-possibility board)) ;次の未確定欄の候補情報::=(行番号 列番号 候補のリスト)
    (setf i (first n-lst) j (second n-lst) lst (third n-lst))
    (setf lst (sort (copy-seq lst) #'<)) ;; 2024-01-31 SBCLのoptimize=3対策。

    (when (and (permit-cheat) (board-p *cheat-board*) (member (cheat-board i j) lst))
      (let (tmp)
        (setf tmp (set-difference lst (list (cheat-board i j)) :test #'equal))
        (setf lst (append (list (cheat-board i j)) tmp))
        )
      )

    (when (check-backtrack-point)
      ;;(print-depth)
      (format t "= ~d行~d列の~aを仮置きの対象にして深さ優先で解を探索します。~%" (1+ i) (1+ j) lst)
      (if (>= (explanation-level) 10) (print-board board)))

    (let (wd)
      (setf wd (width *board-size*))
      (setf fmt (format nil "仮置き(~~~d\d行~~~d\d列[~~~d\d])" wd wd wd))
      (setf msg (concatenate 'string (format nil fmt (1+ i) (1+ j) (first lst)) "を開始"))
      (setf strlen (+ 14 (* wd 3))) ;「半角」で(14 + [wd]x3)文字分の長さ。
      (plot-info msg *difficulty-trial-and-error* (+ strlen 6) "*"))

    (loop
       (when (null lst)
         (depth (1- (depth)))
         (return-from do-trial-and-error nil))

       (setf (aref board i j) (first lst))
       (setf p (simple-numberplace-kernel board))
       (debug-write "do-trial-and-error" (format nil "i=~d, j=~d => ~d" (1+ i) (1+ j) (first lst)))
       (cond
         ((finished-p p)                ;正解に到達。
          (setf msg (concatenate 'string (format nil fmt (1+ i) (1+ j) (first lst)) "は正解"))
          (plot-info msg *difficulty-mark* (+ strlen 6) "O")
          (when (check-backtrack-point)
            ;;(print-depth)
            (format t "! ~d行~d列が[~d]という仮定は成立しました。" (1+ i) (1+ j) (first lst))
            (format t "正解が得られました。~%"))
          (if (>= (explanation-level) 10) (print-board p))
          (cond
            ((need-multiple-answer)
             (when (check-backtrack-point)
               ;;(print-depth)
               (format t "* 他の解が存在しないか探索を続けます。~%"))
             (answer (cons p (answer)))
             (pop lst))
            (t (answer p)
               (throw 'search-finished (answer))
               ;;(return-from do-trial-and-error (answer))
               )))
         ((conflict-p p)          ;盤面に矛盾 = 仮置きした候補が誤り。
          (setf msg (concatenate 'string (format nil fmt (1+ i) (1+ j) (first lst)) "は矛盾"))
          (plot-info msg *difficulty-mark* (+ strlen 6) "X")
          (when (check-backtrack-point)
            ;;(print-depth)
            (format t "? ~d行~d列が[~d]ではボードに矛盾が生じます。" (1+ i) (1+ j) (first lst))
            (format t "別の可能性を試します。~%"))
          (if (>= (explanation-level) 20) (print-board p))
          (pop lst))
         ((do-trial-and-error p))
         (t    ;探索を続けても正解なし。セル内の次の候補で探索を継続。
          (setf msg (concatenate 'string (format nil fmt (1+ i) (1+ j) (first lst)) "は不正解"))
          (plot-info msg *difficulty-mark* (+ strlen 8) "X")
          (when (check-backtrack-point)
            ;;(print-depth)
            (format t "* ~d行~d列に[~d]を仮定すると正解がありませんでした。"
                    (1+ i) (1+ j) (first lst))
            (format t "セルの残りの候補に対して探索を続けます。~%"))
          (if (>= (explanation-level) 20) (print-board p))
          (pop lst))) ;; end cond
       ) ;; end loop
    ) ;; end let
  ) ;; end defun

(defun conflict-p (board)
"ボードに矛盾があれば[t]を、そうでなければ[nil]を返す。"
  (not (consistent-p board)))

(defun easy-check (board)
"空欄(内容が[nil])のセルがあれば[nil]を、そうでなければ[t]を返す。"
  (dotimes (i *board-size*)
    (dotimes (j *board-size*)
      (if (null (aref board i j)) (return-from easy-check nil)
	  ) ;; end if
      ) ;; end dotimes
    ) ;; end dotimes
  (return-from easy-check t))

(defun consistent-p (board)
"与えられたボード[board]に矛盾がないか調べる。矛盾がなければ[t]を返す。そうでなければ[nil]を返す。"
  (and
   (board-p board)
   (check-block-consistency board)
   (check-row-consistency board)
   (check-col-consistency board)))

(defun inconsistent-p (board)
"与えられたボード[board]に矛盾があれば[t]、なければ[nil]を返す。"
  (not (consistent-p board)))

(defun check-block-consistency (board)
  (let ((complete t) (i 0))
    (loop
       (if (null complete) (return nil))
       (if (>= i *board-size*) (return complete))
       (setf complete (check-block-consistency-sub i board))
       (incf i))))

(defun check-block-consistency-sub (block-num board)
  (let ((row nil) (col nil) (r nil) (lst nil))
    (setf row (block-base-row block-num)) ;; row-base
    (setf col (block-base-col block-num)) ;; col-base
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (setf r (aref board (+ row i) (+ col j)))
        (if (null r) (return-from check-block-consistency-sub nil))
        (when (integerp r)
          (if (intersection (list r) lst) (return-from check-block-consistency-sub nil))
          (setf lst (union (list r) lst)))))
    (return-from check-block-consistency-sub t)))

(defun check-row-consistency (board)
  (let ((complete t) (i 0))
    (loop
       (if (null complete) (return nil))
       (if (>= i *board-size*) (return complete))
       (setf complete (check-row-consistency-sub i board))
       (incf i))))

(defun check-row-consistency-sub (row-num board)
  (let ((r nil) (lst nil))
    (dotimes (j *board-size*)
      (setf r (aref board row-num j))
      (if (null r) (return-from check-row-consistency-sub nil))
      (when (integerp r)
        (if (intersection (list r) lst) (return-from check-row-consistency-sub nil))
        (setf lst (union (list r) lst))))
    (return-from check-row-consistency-sub t)))

(defun check-col-consistency (board)
  (let ((complete t) (i 0))
    (loop
       (if (null complete) (return nil))
       (if (>= i *board-size*) (return complete))
       (setf complete (check-col-consistency-sub i board))
       (incf i))))

(defun check-col-consistency-sub (col-num board)
  (let ((r nil) (lst nil))
    (dotimes (i *board-size*)
      (setf r (aref board i col-num))
      (if (null r) (return-from check-col-consistency-sub nil))
      (when (integerp r)
        (if (intersection (list r) lst) (return-from check-col-consistency-sub nil))
        (setf lst (union (list r) lst))))
    (return-from check-col-consistency-sub t)))

(defun finished-p (board)
"ナンプレ（Number Place）の完成条件を満たしているかチェックする。"
  (and
   (board-p board)
   (check-all-block board)
   (check-all-row board)
   (check-all-col board)))

(defun check-all-block (board)
  (let ((complete t) (i 0))
    (loop
       (if (null complete) (return nil))
       (if (>= i *board-size*) (return complete))
       (setf complete (check-block i board))
       (incf i))))

(defun check-block (block-num board)
  (let ((row nil) (col nil) (r nil) (lst *np-digit*))
    (setf row (block-base-row block-num)) ;; row-base
    (setf col (block-base-col block-num)) ;; col-base
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (setf r (aref board (+ row i) (+ col j)))
        (debug-write
         "check-block" (format nil "(board ~d ~d)=~d, lst=~a" (+ row i) (+ col j) r lst))
        (if (null r) (return-from check-block nil))
        (if (member r lst) (setf lst (remove r lst)))))
    (if (= (length lst) 0) t nil)))

(defun check-all-row (board)
  (let ((complete t) (i 0))
    (loop
       (if (null complete) (return nil))
       (if (>= i *board-size*) (return complete))
       (setf complete (check-row i board))
       (incf i))))

(defun check-row (row-num board)
  (let ((r nil) (lst *np-digit*))
    (dotimes (j *board-size*)
      (setf r (aref board row-num j))
      (if (null r) (return-from check-row nil))
      (if (member r lst) (setf lst (remove r lst))))
    (if (= (length lst) 0) t nil)))

(defun check-all-col (board)
  (let ((complete t) (i 0))
    (loop
       (if (null complete) (return nil))
       (if (>= i *board-size*) (return complete))
       (setf complete (check-col i board))
       (setf i (1+ i)))))

(defun check-col (col-num board)
  (let ((r nil) (lst *np-digit*))
    (dotimes (i *board-size*)
      (setf r (aref board i col-num))
      (if (null r) (return-from check-col nil))
      (if (member r lst) (setf lst (remove r lst))))
    (if (= (length lst) 0) t nil)))

(defun no-candidate-p (board)
"確定値と未確定値だけからなるボードかをチェックする。"
  (when (board-p board)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (if (listp (aref board i j)) (return-from no-candidate-p nil))))
    (return-from no-candidate-p t))
  (return-from no-candidate-p nil))

(defun do-obvious (board)
"行、列、ブロックに対して、すでに8コの数字が確定している場所がないかチェックする。
もしあれば確定する数字を当てはめたボードを返す。2024-01-17"
  (let (info info-list)
    (setf info-list nil)
    (if (null (easy-check board)) (return-from do-obvious board))
    (dotimes (i *board-size*)
      (multiple-value-setq (board info) (do-obvious-row i board))
      (if (identity info) (push info info-list))
      )
    (dotimes (j *board-size*)
      (multiple-value-setq (board info) (do-obvious-col j board))
      (if (identity info) (push info info-list))
      )
    (dotimes (k *board-size*)
      (multiple-value-setq (board info) (do-obvious-block k board))
      (if (identity info) (push info info-list))
      )
    (return-from do-obvious (values board info-list))
    )
  )

(defun exec-obvious (board)
  (let (brd)
    (setf brd (new-board board))
    (loop
       (setf brd (do-obvious brd))
       (if (equal-board-p brd board) (return))
       (setf board (new-board brd)))
    (return-from exec-obvious brd)))

;;; 指定された行内の数字8コが確定していたら残りの数字を当てはめて返す。2024-01-17
(defun do-obvious-row (row-num board)
  (let ((q nil) (r nil) (lst *np-digit*) info)
    (setf info nil)
    (dotimes (j *board-size*)
      (setf r (aref board row-num j))
      (if (member r lst)
          (setf lst (remove r lst))
          (setf q j)))
    (when (and (= (length lst) 1) (pure-listp (aref board row-num q)))
      (setf (aref board row-num q) (first lst))
      (plot-info "残り物" *difficulty-obvious* 6)
      (method-applied 'do-obvious-row)
      (if (snap-shot-p row-num q (first lst)) (print-snap-shot board row-num q))
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (format t "~d行目で~dコの数字が確定しています。" (1+ row-num) (1- *board-size*))
        (format t "~d行~d列は ~dです。~%" (1+ row-num) (1+ q) (first lst))
        ;; 2024-01-17
        ;;(push (list 'do-obvious (list 'fix (list (list 'row row-num) (first lst)))
        ;;            (list 'fix (list 'cell (list (list row-num q) (first lst))))) info)
        (push (list 'do-obvious 'fix-last-candidate (list 'row row-num)
		    (list 'mustbe (list row-num q) (first lst))) info) ;; 2024-02-25
        ) ;; end when
      (if (trim-every-time) (setf board (do-trim-group board row-num q))) ;2009/02/01 07:00
      (if (>= (explanation-level) 10) (print-board board)))
    (return-from do-obvious-row (values board info))))

;;; 指定された列内の数字8コが確定していたら残りの数字を当てはめて返す。
(defun do-obvious-col (col-num board)
  (let ((p nil) (r nil) (lst *np-digit*) info)
    (setf info nil)
    (dotimes (i *board-size*)
      (setf r (aref board i col-num))
      (if (member r lst)
          (setf lst (remove r lst))
          (setf p i)))
    (when (and (= (length lst) 1) (pure-listp (aref board p col-num)))
      (setf (aref board p col-num) (first lst))
      (plot-info "残り物" *difficulty-obvious* 6)
      (method-applied 'do-obvious-col)
      (if (snap-shot-p p col-num (first lst)) (print-snap-shot board p col-num))
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (format t "~d列目で~dコの数字が確定しています。" (1+ col-num) (1- *board-size*))
        (format t "~d行~d列は ~dです。~%" (1+ p) (1+ col-num) (first lst)))
        ;; 2024-01-17
        ;;(push (list 'do-obvious (list 'fix (list (list 'col col-num) (first lst)))
        ;;            (list 'fix (list 'cell (list (list col-num p) (first lst))))) info)
        (push (list 'do-obvious 'fix-last-candidate (list 'col col-num)
		    (list 'mustbe (list p col-num) (first lst))) info) ;; 2024-02-26
      (if (trim-every-time) (setf board (do-trim-group board p col-num)))       ;2009/02/01 07:00
      (if (>= (explanation-level) 10) (print-board board)))
    (return-from do-obvious-col (values board info))))

;;; 指定されたブロック内の数字8コが確定していたら残りの数字を当てはめて返す。
(defun do-obvious-block (blk-num board)
  (let ((row nil) (col nil) (p nil) (q nil) (r nil) (lst *np-digit*) info)
    (setf info nil)
    (setf row (block-base-row blk-num)) ;; row-base
    (setf col (block-base-col blk-num)) ;; col-base
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (setf r (aref board (+ row i) (+ col j)))
        (if (member r lst)
            (setf lst (remove r lst))
            (progn
              (setf p (+ row i))     ;; 未確定要素の行番号
              (setf q (+ col j)))))) ;; 未確定要素の列番号
    (when (and (= (length lst) 1) (pure-listp (aref board p q))) ;; 未確定要素はひとつか？
      (setf (aref board p q) (first lst))
      (plot-info "残り物" *difficulty-obvious* 6)
      (method-applied 'do-obvious-block)
      (if (snap-shot-p p q (first lst)) (print-snap-shot board p q))
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (format t "ブロック~dで~dコの数字が確定しています。" (1+ blk-num) (1- *board-size*))
        (format t "~d行~d列は ~dです。~%" (1+ p) (1+ q) (first lst)))
        ;; 2024-01-17
        ;;(push (list 'do-obvious (list 'fix (list (list 'block (blk-num p q)) (first lst)))
        ;;            (list 'fix (list 'cell (list (list p q) (first lst))))) info)
        (push (list 'do-obvious 'fix-last-candidate (list 'block blk-num)
		    (list 'mustbe (list p q) (first lst))) info) ;; 2024-02-26
      (if (trim-every-time) (setf board (do-trim-group board p q))) ;2009/02/01 07:00
      (if (>= (explanation-level) 10) (print-board board)))
    (return-from do-obvious-block (values board info))))

(defun do-trim (board)
"ボード全体に対して刈り込みを行う。*chain-trim*が[t]ならば、確定値が発生した場合
再帰的に刈り込みを続ける。"
  (let (brd cell)
    (if (null (easy-check board)) (return-from do-trim board)) ;内容が[nil]のセルがあれば終了。
    (setf brd (new-board board))        ;刈り込み実行前の盤面
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf cell (aref board i j))
        ;;セル内に唯一の候補があれば確定値。
        (if (and (pure-listp cell) (= (length cell) 1)) (setf (aref board i j) (first cell)))
        (if (integerp (aref board i j)) (setf board (do-trim-group board i j)))))
    (when (not (equal-board-p board brd))
      (plot-info "盤面刈り込み" *difficulty-trim* 12)
      (method-applied 'do-trim)
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (format t "ボード全体に対して刈り込みを行いました。~%")
        (if (>= (explanation-level) 10) (print-board board))))
    (return-from do-trim board)))

;;; 未確定セル数が全セル数の[ratio]%未満ならば刈り込みを行う。
(defun do-auto-trim (board ratio)
  (cond
    ((>= ratio 100)
     (setf board (do-trim board)))
    ((< (candidate-ratio board) ratio)
     (setf board (do-trim board))))
  (return-from do-auto-trim board))

;;; ボード[board]内の候補セルの比率[0..100]を返す。
(defun candidate-ratio (board)
  (let ((count 0))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (if (not (integerp (aref board i j))) (incf count))))
    (return-from candidate-ratio (* (/ count (* *board-size* *board-size*)) 100)) ))

;;; [p]行[q]列の確定値を、属する行・列・ブロック内の候補から取り除いたボードを返す。
(defun do-trim-group (board p q)
  (when (>= (mod (explanation-level) 10) 2)
    ;;(print-depth)
    (format t "~d行~d列が~dなので同じユニットから~dを取り除きます。~%"
            (1+ p) (1+ q) (aref board p q) (aref board p q)))
  (if (>= (explanation-level) 20) (print-board board))
  (setf board (do-trim-row board p q))
  (setf board (do-trim-col board p q))
  (setf board (do-trim-block board p q))
  (return-from do-trim-group board))
      
;;; [p]行[q]列の値と同じ数字をp行内の候補リストから刈り込む。
(defun do-trim-row (board p q)
  (let (num)
    (setf num (aref board p q))
    (when (not (integerp num))
      (debug-write "do-trim-row" (format nil "(aref board ~d ~d) must be number." p q))
      (break))
    (setf num (list num))
    (dotimes (j *board-size*)
      (when (pure-listp (aref board p j))
        (setf board (delete-candidate num p j board)))
      (when (and (pure-listp (aref board p j)) (= (length (aref board p j)) 1))
        (setf (aref board p j) (first (aref board p j)))
        (if (snap-shot-p p j (aref board p j)) (print-snap-shot board p j))
        (if (chain-trim) (setf board (do-trim-group board p j)))))
    (if (debug-write "do-trim-row" (format nil "p=~d,q=~d" (1+ p) (1+ q))) (print-normal board))
    (return-from do-trim-row board)))

;;; [p]行[q]列の値と同じ数字をq列内の候補リストから刈り込む。
(defun do-trim-col (board p q)
  (let (num)
    (setf num (aref board p q))
    (when (not (integerp num))
      (debug-write "do-trim-col" (format nil "(aref board ~d ~d) must be number." p q))
      (break))
    (setf num (list num))
    (dotimes (i *board-size*)
      (when (pure-listp (aref board i q))
        (setf board (delete-candidate num i q board)))
      (when (and (pure-listp (aref board i q)) (= (length (aref board i q)) 1))
        (setf (aref board i q) (first (aref board i q)))
        (if (snap-shot-p i q (aref board i q)) (print-snap-shot board i q))
        (if (chain-trim) (setf board (do-trim-group board i q)))))
    (if (debug-write "do-trim-col" (format nil "p=~d,q=~d" (1+ p) (1+ q))) (print-normal board))
    (return-from do-trim-col board)))

;;; [p]行[q]列の値と同じ数字を(block-num p q)ブロック内の候補リストから刈り込む。
(defun do-trim-block (board p q)
  (let (row col num blk)
    (setf num (aref board p q))
    (when (not (integerp num))
      (debug-write "do-trim-block" (format nil "(aref board ~d ~d) must be number." p q))
      (break))
    (setf num (list num))
    (setf blk (block-num p q))
    (setf row (block-base-row blk)) ;; row-base
    (setf col (block-base-col blk)) ;; col-base
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (when (pure-listp (aref board (+ row i) (+ col j)))
          (setf board (delete-candidate num (+ row i) (+ col j) board)))
        (when (and (pure-listp (aref board (+ row i) (+ col j)))
                   (= (length (aref board (+ row i) (+ col  j))) 1))
          (setf (aref board (+ row i) (+ col j)) (first (aref board (+ row i) (+ col j))))
          (if (snap-shot-p i j (aref board (+ row i) (+ col j)))
              (print-snap-shot board (+ row i) (+ col j)))
          (if (chain-trim) (setf board (do-trim-group board (+ row i) (+ col j)))))))
    (if (debug-write "do-trim-block" (format nil "p=~d,q=~d" (1+ p) (1+ q))) (print-normal board))
    (return-from do-trim-block board)))

;;; [p]行[q]列から候補[num]を削除する。
(defun do-trim-cell (num board p q)
  (when (pure-listp (aref board p q))
    (cond
      ((pure-listp num) ;; 2024-03-04
       (setf board (delete-candidate num p q board))
       )
      ((numberp num)
       (setf board (delete-candidate (list num) p q board))
       )
      (t (error "error at do-trim-cell."))
      )					  ;; end cond
    (when (= (length (aref board p q)) 1) ;[nil]の場合も何もしない。
      (setf (aref board p q) (first (aref board p q)))
      (if (snap-shot-p p q (aref board p q)) (print-snap-shot board p q))
      (if (chain-trim) (setf board (do-trim-group board p q))) ))
  (return-from do-trim-cell board))

(defun block-num (i j)
"i行j列の属するブロック番号を返す。"
  (+ (* (floor i *block-size*) *block-size*) (floor j *block-size*)))

(defun block-base-row (blk-num)
"ブロック番号[blk-num]の左上のセルが属する行番号を返す。"
  (* (floor blk-num *block-size*) *block-size*))

(defun block-base-col (blk-num)
"ブロック番号[blk-num]の左上のセルが属する列番号を返す。"
  (* (mod blk-num *block-size*) *block-size*))

(defun block-base-cell (blk-num)
"ブロック番号[blk-num]の左上のセルのアドレスを返す。"
  (list (block-base-row blk-num) (block-base-col blk-num)))

(defun same-block-cells (cell)
"指定されたセルを含むブロック内のすべてのセル・アドレスのリストを返す。"
  (let (row col blk-num row-base col-base result)
    (setf row (first cell))
    (setf col (second cell))
    (setf blk-num (block-num row col))
    (setf row-base (block-base-row blk-num))
    (setf col-base (block-base-col blk-num))
    (setf result nil)
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (push (list (+ row-base i) (+ col-base j)) result)))
    (return-from same-block-cells (reverse result))))

(defun same-block-cells-for-block (blk-num)
"ブロック番号[blk-num]内のすべてのセル・アドレスのリストを返す。"
  (same-block-cells (block-base-cell blk-num)))

(defun same-block-p (cell-1 cell-2)
"ふたつのセル[cell-1]と[cell-2]が同じブロックに属していれば[t]、そうでなければ[nil]。"
  (let (row-1 col-1 row-2 col-2)
    (setf row-1 (first cell-1) col-1 (second cell-1))
    (setf row-2 (first cell-2) col-2 (second cell-2))
    (return-from same-block-p (= (block-num row-1 col-1) (block-num row-2 col-2)))))

(defun same-row-cells (cell)
"指定されたセルを含む行内のすべてのセル・アドレスのリストを返す。"
  (let (row result)
    (setf row (first cell))
    (setf result nil)
    (dotimes (j *board-size*)
      (push (list row j) result))
    (return-from same-row-cells (reverse result))))

(defun same-row-cells-for-row (row-num)
"行番号[row-num]で指定された行に含まれる全てのセル・アドレスのリストを返す。"
  (same-row-cells (list row-num 0))
  )

(defun same-col-cells-for-col (col-num)
"列番号[col-num]で指定された列に含まれる全てのセル・アドレスのリストを返す。"
  (same-col-cells (list 0 col-num))
  )

(defun same-row-p (cell-1 cell-2)
"ふたつのセル[cell-1]と[cell-2]が同じ行に属していれば[t]、そうでなければ[nil]。"
  (return-from same-row-p (equal (first cell-1) (first cell-2))))

(defun same-col-cells (cell)
"指定されたセルを含む列内のすべてのセル・アドレスのリストを返す。"
  (let (col result)
    (setf col (second cell))
    (setf result nil)
    (dotimes (i *board-size*)
      (push (list i col) result))
    (return-from same-col-cells (reverse result))))

(defun same-col-p (cell-1 cell-2)
"ふたつのセル[cell-1]と[cell-2]が同じ列に属していれば[t]、そうでなければ[nil]。"
  (return-from same-col-p (equal (second cell-1) (second cell-2))))

(defun same-house-cells (cell)
"指定されたセルを含むユニット内のすべてのセル・アドレスのリストを返す。"
  (same-unit-cells cell))

(defun same-unit-cells (cell)
"same-house-cellsの別名関数。"
  (let (result)
    (setf result (union (same-row-cells cell) (same-col-cells cell) :test #'equal))
    (setf result (union (same-block-cells cell) result :test #'equal))
    (setf result (sort (copy-seq result) #'cell-order-p)) ;必須ではない。
    (return-from same-unit-cells result)))

(defun all-cells ()
"ボード内のすべてのセル・アドレスを返す。"
  (let (cells)
    (setq cells nil)
    (dotimes (i (board-size))
      (dotimes (j (board-size))
	(push (list i j) cells)
	)
      )
    (return-from all-cells (reverse cells))
    )
  )

(defun same-unit-p (cell-1 cell-2)
"ふたつのセル[cell-1]と[cell-2]が同じユニット(あるセルに対するグループ)に
含まれているかどうかを返す。"
  (let (row-1 col-1 row-2 col-2)
    (setf row-1 (first cell-1) col-1 (second cell-1))
    (setf row-2 (first cell-2) col-2 (second cell-2))
    (or
     (equal row-1 row-2)
     (equal col-1 col-2)
     (equal (block-num row-1 col-1) (block-num row-2 col-2)))))

(defun all-same-unit-p (cell-list)
"セルのリスト[cell-list]に含まれるすべてのセルが同じユニットに含まれているかどうかを返す。
[cell-list] ::= ( [セルアドレス]... ) ;
[返り値] ::= ( 'row | 'col | 'block ) | nil ;
ex. (all-same-unit-p '((3 1) (3 2))) ==> (block row)"
  (let (result)
    (if (null cell-list) (return-from all-same-unit-p nil))
    (setf result nil)
    (if (all-same-row-p cell-list)   (push 'row result))
    (if (all-same-col-p cell-list)   (push 'col result))
    (if (all-same-block-p cell-list) (push 'block result))
    (return-from all-same-unit-p result)))

(defun all-same-row-p (cell-list)
"セルアドレスのリスト[cell-list]に含まれるすべてのセルが同じ行に含まれているかどうかを返す。"
  (let (first-cell rest-cell-list result)
    (if (null cell-list) (return-from all-same-row-p nil))
    (setf result t)
    (setf first-cell (first cell-list))
    (setf rest-cell-list (cdr cell-list))
    (dolist (p rest-cell-list)
      (setf result (and result (same-row-p first-cell p)))
      )
    (return-from all-same-row-p result)))

(defun all-same-col-p (cell-list)
"セルアドレスのリスト[cell-list]に含まれるすべてのセルが同じ列に含まれているかどうかを返す。"
  (let (first-cell rest-cell-list result)
    (if (null cell-list) (return-from all-same-col-p nil))
    (setf result t)
    (setf first-cell (first cell-list))
    (setf rest-cell-list (cdr cell-list))
    (dolist (p rest-cell-list)
      (setf result (and result (same-col-p first-cell p)))
      )
    (return-from all-same-col-p result)))

(defun all-same-block-p (cell-list)
"セルアドレスのリスト[cell-list]に含まれるすべてのセルが同じブロックに含まれているかどうかを返す。"
  (let (first-cell rest-cell-list result)
    (if (null cell-list) (return-from all-same-block-p nil))
    (setf result t)
    (setf first-cell (first cell-list))
    (setf rest-cell-list (cdr cell-list))
    (dolist (p rest-cell-list)
      (setf result (and result (same-block-p first-cell p)))
      )
    (return-from all-same-block-p result)))

(defun same-house-p (cells-1 cells-2)
"セルのリスト[cells-1]と[cells-2]が同一のハウスに属しているかどうかを返す。
属していれば、それぞれのセルリストの属すユニット同士の共通要素となるセルアドレスを返す。
そうでなければ[nil]を返す。

Example:
 cl-user> (setf cells-1 '((3 1) (3 2) (3 5)))
 ((3 1) (3 2) (3 5))
 cl-user> (setf cells-2 '((4 0) (5 0)))
 ((4 0) (5 0))
 cl-user> (setf cells-3 '((0 1) (1 1)))
 ((0 1) (1 1)) 
 cl-user> (same-house-p cells-1 cells-2)
 ((3 0) (3 1) (3 2))
 cl-user> (same-house-p cells-2 cells-3)
 ((3 1) (4 1) (5 1) (0 0) (1 0) (2 0))"
  (let (grp-1 grp-2 result)
    (if (or (null cells-1) (null cells-2)) (return-from same-house-p nil))
    (setf grp-1 (all-same-unit-p cells-1))
    (if (null grp-1) (return-from same-house-p nil))
    (setf grp-2 (all-same-unit-p cells-2))
    (if (null grp-2) (return-from same-house-p nil))
    (setf result nil)
    (dolist (p grp-1)
      (dolist (q grp-2)
        (cond
          ((equal p q)
           (do-nothing))
          ((and (eq p 'block) (eq q 'row))
           (setf result (union
            (intersection (same-block-cells (first cells-1)) (same-row-cells (first cells-2)) :test #'equal)
            result :test #'equal)))
          ((and (eq p 'block) (eq q 'col))
           (setf result (union
            (intersection (same-block-cells (first cells-1)) (same-col-cells (first cells-2)) :test #'equal)
            result :test #'equal)))
          ((and (eq p 'row) (eq q 'block))
           (setf result (union
            (intersection (same-row-cells (first cells-1)) (same-block-cells (first cells-2)) :test #'equal)
            result :test #'equal)))
          ((and (eq p 'row) (eq q 'col))
           (setf result (union
            (intersection (same-row-cells (first cells-1)) (same-col-cells (first cells-2)) :test #'equal)
            result :test #'equal)))
          ((and (eq p 'col) (eq q 'block))
           (setf result (union
            (intersection (same-col-cells (first cells-1)) (same-block-cells (first cells-2)) :test #'equal)
            result :test #'equal)))
          ((and (eq p 'col) (eq q 'row))
           (setf result (union
            (intersection (same-col-cells (first cells-1)) (same-row-cells (first cells-2)) :test #'equal)
            result :test #'equal)))
          )
        )
      )
    (return-from same-house-p result) ) )

(defun cell-order-p (cell-1 cell-2)
"セル[cell-1]と[cell-2]を比較して[cell-1]の順序の方が前なら[t]、そうでないなら[nil]を返す。"
  (let (row-1 col-1 row-2 col-2)
    (setf row-1 (first cell-1) col-1 (second cell-1))
    (setf row-2 (first cell-2) col-2 (second cell-2))
    (cond
      ((< row-1 row-2) t)
      ((> row-1 row-2) nil)
      ((< col-1 col-2) t)
      ((> col-1 col-2) nil)
      (t t)) ;;すべて同じなら順序を変えない。
    ) ;; end let
  )


(defun delete-candidate (num-list i j brd)
"ボード[brd]の[i]行[j]列から候補のリスト[num-list]を削除する。
候補を削除した結果[nil]あるいは単独の候補だけが残ることも許す。"
  (let (tmp)
    (setf tmp (set-difference (aref brd i j) num-list :test #'equal)) ;2009/02/21
    (setf tmp (sort (copy-seq tmp) #'<))
    (setf (aref brd i j) tmp)
    (return-from delete-candidate brd)))

(defun do-pattern-overlay-method (board)
  "配置確定法(Pattern Overlay Method)の実装

候補が存在する可能性がある位置を示した表[check-board]から、ナンプレのルール下で
あり得る存在パターンを特定し候補位置を絞り込む。

ある位置の候補を仮定した場合、各ブロック／行／列内に存在していた候補がすべ
て消えてしまう場合は仮定が誤り。矛盾が発生するパターンは廃棄。

すべてのパターンに共通する存在可能位置があれば確定値。
すべてのパターンに現れない位置があれば候補を削除可能。"
  (let (brd chk-brd fix-brd del-cand-brd count color-brd info patterns
	mustbe-cells-list cannotbe-cells-list)

    (if (null (easy-check board)) (return-from do-pattern-overlay-method (values board info)))

    ;; 初期設定
    (setf info nil)
    (setf brd (new-board board))

    (dolist (num *np-digit*) ;; 候補数字1...*np-digit*(9x9ナンプレなら9)までの各数字に対して。
      (block pattern-overlay-method-loop

	(debug-write "do-pattern-overlay-method-1" (format nil "num=~d~%" num))

	(setf chk-brd (make-check-board num brd)) ;; 候補数字[num]が存在し得るセルだけを[t]にした盤面を用意。
	(setf color-brd (new-board board))

	(setf count 0)
	(dotimes (i *board-size*) ;; 候補数字[num]が存在し得るセルの数を数える。
          (dotimes (j *board-size*)
            (if (aref chk-brd i j) (incf count))
            ) ;; end dotimes
          )   ;; end dotimes
	
	(when (debug-write-p "do-pattern-overlay-method-2")
          (format t "候補~dを含むセルは~dカ所あります。~%" num count)
          (print-check-board chk-brd brd)
	  )

	;; 候補数字[num]が存在し得るセルがひとつもないなら次の候補数字について探索する。
	(if (null-board-p chk-brd) (return-from pattern-overlay-method-loop nil))
	
	;; [fix-brd]と[del-cand-brd]が確定値と削除可能候補値を含んでいる。ほぼ答えそのもの。
	;;=========================================================================================
	;; 渡されたチェックボードを元に確定値となるセル位置と、削除可能なセル位置が記されたボードを返す。
	(debug-write "do-pattern-overlay-method-2-1" (format nil "find-valid-pattern for ~d~%" num))
	(multiple-value-setq (fix-brd del-cand-brd patterns) (find-valid-pattern chk-brd))
	;;=========================================================================================

	;; 候補数字[num]が存在し得る場所はなかった。
	(if (and (null-board-p fix-brd) (null-board-p del-cand-brd))
            (return-from pattern-overlay-method-loop nil)) ;; 次のループへ。2024-04-18 bug fix.

	(plot-info "配置確定法" *difficulty-pattern-overlay-method* 10) ;実際に適用できたときのみカウントする。
	(method-applied 'do-pattern-overlay-method)

        ;; [手筋情報]を作成する。2024-01-17
	(let (msg msg-1 msg-2 msg-3)
	  (record-quiz-info :function-name 'do-pattern-overlay-method)
	  (setq msg-1 (format nil "候補数字~dに対する~d種類の有効な配置パターンから" num (length patterns)))
	  (setq msg-2 (format nil "共通位置とまったく現れない位置を探す。~%"))
	  (setq msg-3 "「有効な配置パターン」とはナンプレのルールを満たす配置パターンのこと。")
	  (setq msg (concatenate 'string msg-1 msg-2 msg-3))
	  (record-quiz-info :explanation msg)
	  ) ;; end let

        ;; [color-brd]を用意する。
	(let (mustbe-cells cannotbe-cells)
	  (setq mustbe-cells nil)
	  (setq cannotbe-cells nil)

	  (when (debug-write-p "do-pattern-overlay-method-3-4")
	    (format t "fix-brd=~a~%" fix-brd)
	    (print-mini fix-brd)
	    (format t "del-cand-brd=~a~%" del-cand-brd)
	    (print-mini del-cand-brd)
	    ) ;; end when

	  (when (not (null-board-p fix-brd)) ;; 確定値となる[num]を含んでいる。
	    (dotimes (i *board-size*)
	      (dotimes (j *board-size*)
		(when (aref fix-brd i j)
		  (push (list 'mustbe (list i j) num) mustbe-cells)
		  (push (list i j num) mustbe-cells-list)
		  (setf color-brd (set-colored-candidate color-brd (list i j) num 'green))
		  (when (debug-write-p "do-pattern-overlay-method-3-5")
		    (format t "green~%")
		    (print-normal color-brd)
		    ) ;; end when
		  )   ;; end when
		)     ;; end dotimes
	      )       ;; end dotimes
	    )

	  (when (not (null-board-p del-cand-brd)) ;; 削除可能な[num]を含んでいる。
	    (dotimes (i *board-size*)
	      (dotimes (j *board-size*)
		(when (aref del-cand-brd i j)
		  (push (list 'cannotbe (list i j) (list num)) cannotbe-cells)
		  (push (list i j num) cannotbe-cells-list)
		  (setf color-brd (set-colored-candidate color-brd (list i j) num '*elimination-color*))
		  (when (debug-write-p "do-pattern-overlay-method-3-5")
		    (format t "*elimination-color*~%")
		    (print-normal color-brd)
		    ) ;; end when
		  )   ;; end when
		)     ;; end dotimes
	      )       ;; end dotimes
	    ) ;; end when

	  (record-quiz-info :position (list num chk-brd patterns))
	  (record-quiz-info :candidate (append mustbe-cells cannotbe-cells))
	  (push (list (record-quiz-info)) info)
	  (reset-record-quiz-info)
	  ) ;; end let

        (debug-write "do-pattern-overlay-method-4" (format nil "info=~a" info))

	(when (>= (mod (explanation-level) 10) 1)

          (when (not (null-board-p fix-brd))
            ;;(print-depth)
            (format t "配置確定法:")
            (cond
              ((show-color-board)
               (print-colored-string 'green (format nil "[~a]" (short-color-name 'green))))
              (t (format t "[~a]" *sharp-mark*)))
            (format t "は[~d]の有効なすべての配置パターンで共通なので確定値です。~%" num)

            (when (print-check)
              (dotimes (i *board-size*)
		(dotimes (j *board-size*)
                  (if (aref fix-brd i j) (setf (aref chk-brd i j) *sharp-mark*))
                  ) ;; end dotimes
		)   ;; end dotimes
              )     ;; end when
            )	    ;; end when

          (when (not (null-board-p del-cand-brd))
            ;;(print-depth)
            (format t "配置確定法:")
            (cond
              ((show-color-board)
               (print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*))))
              (t (format t "[~a]" *at-mark*)))
            (format t "の位置に[~d]を配置することはできないので削除できます。~%" num)
            
            (when (debug-write-p "do-pattern-overlay-method-1")
              (format t "info=~a~%" info)
              (print-mini del-cand-brd)
              )

            (when (print-check)
              (dotimes (i *board-size*)
		(dotimes (j *board-size*)
                  (if (aref del-cand-brd i j) (setf (aref chk-brd i j) *at-mark*))
		  ) ;; end dotimes
		)   ;; end dotimes
	      )	    ;; end when
	    )	    ;; end when

          (when (print-check)
            (cond
              ((show-color-board)
               (print-normal color-brd))
              (t (print-check-board chk-brd brd)))
            ) ;; end when

          ) ;; end when (>= (mod (explanation-level) 10) 1)
	)   ;; end block pattern-overlay-method-loop
      )	    ;; end dolist

    (dolist (p mustbe-cells-list)
      (setf (aref brd (first p) (second p)) (third p))
      )
    (dolist (p cannotbe-cells-list)
      (if (pure-listp (aref brd (first p) (second p))) ;; 確定値に変化している可能性がある。
	  (setq brd (delete-candidate (list (third p)) (first p) (second p) brd))
	  ) ;; end if
      )
    (setf brd (clean-up-board brd))

    (if (>= (explanation-level) 10) (print-board brd))

    (debug-write "do-pattern-overlay-method-2" (format nil "returns brd and ~a~%" info))
    (return-from do-pattern-overlay-method (values brd (list info)))
    ) ;; end let
  ) ;; end do-pattern-overlay-method

(defun exec-pattern-overlay-method (board)
  (let (brd)
    (setf brd (new-board board))
    (setf brd (do-trim brd))
    ;;(setf brd (do-fundamental brd)) ;; 2024-01-19
    ;;(setf brd (do-cell-unique brd))
    (loop
       (setf brd (do-pattern-overlay-method brd))
       (if (equal-board-p brd board) (return))
       (setf board (new-board brd)))
    (return-from exec-pattern-overlay-method brd)))

(defun find-valid-pattern (check-board)
"渡されたチェックボードを元に有効な配置を探し共通する部分があれば、その表を返す。
[check-board]は候補数字が存在し得るセルだけを[t]に、他のセルは[nil]に設定したボード。

返り値の[fix-brd]内で[t]が記録されているセルは、ナンプレのルール上有効な全ての配置パターンで共通なセルなので確定値。
返り値の[del-cand-brd]内で[t]が記録されているセルは、候補数字が存在するが、ナンプレのルール上有効などの配置パターン
にも一致しないセルなので、そのセル内の候補数字は削除できる。
"
  (let (patterns fix-brd del-cand-brd brd org-brd number-of-pattern first-cell)
    (if (debug-write "find-valid-pattern" "check-board is...") (print-mini check-board))
    (setf fix-brd (make-array (list *board-size* *board-size*) :initial-element t))
    (setf del-cand-brd (make-array (list *board-size* *board-size*) :initial-element nil))
    (setf brd (new-board check-board))
    (setf org-brd (new-board check-board))

    (block find-first-cell-loop ;; 候補数字が存在する一番「若い」セルを探す。
      (setq first-cell nil)
      (dotimes (i *board-size*)
	(dotimes (j *board-size*)
	  (when (aref org-brd i j)
	    (setq first-cell (list i j))
	    (return-from find-first-cell-loop first-cell)
	    ) ;; end when
	  )   ;; end dotimes
	)     ;; end dotimes
      ) ;; end block

    (when (debug-write-p "find-valid-pattern")
      (format t "org-brd=~%")
      (print-mini org-brd)
      ) ;; end when

    ;;(setf patterns (find-valid-pattern-sub brd '(0 0) org-brd)) ;; 初期状態では[brd]も[org-brd]も同内容。
    (setf patterns (find-valid-pattern-sub brd first-cell org-brd)) ;; 初期状態では[brd]も[org-brd]も同内容。

    (when (debug-write "find-valid-pattern-print" "可能な配置パターンは次の通りです。")
      (setf number-of-pattern 0)
      (dolist (k patterns)
        (format t "パターン ~d~%" (incf number-of-pattern))
        (print-mini k)
	)		 ;; end dolist
      )			 ;; end when

    (dolist (k patterns) ;; すべてのパターンに共通する部分を探す。
      (dotimes (i *board-size*)
        (dotimes (j *board-size*)
	  ;; 候補数字が存在するボードと、候補数字が存在し得る全てのパターンとの積を取って残ったセルは
	  ;; 全てのパターンで共通するセル。
          (setf (aref fix-brd i j) (and (aref fix-brd i j) (aref k i j)))

	  ;; [del-cand-brd]は候補数字が互いに存在し得る全てのパターンの和集合。
          (setf (aref del-cand-brd i j) (or (aref del-cand-brd i j) (aref k i j)))
          )                   ;; end dotimes
        )                     ;; end dotimes
      )                       ;; end dolist

    (dotimes (i *board-size*) ;; 候補数字が存在するが有効な配置パターンでないセルを得る。
      (dotimes (j *board-size*)
	(when (aref check-board i j)
	  (if (not (aref del-cand-brd i j)) ;; 候補数字が存在するが、ナンプレのルール上存在し得る位置ではなかった。
	      (setf (aref del-cand-brd i j) t) ;; (aref del-cand-brd i j)の位置の候補数字は削除できる。
	      (setf (aref del-cand-brd i j) nil)
	      ) ;; end if
	  )	;; end when
	)	;; end dotimes
      )	    ;; end dotimes

    (when (debug-write-p "find-valid-pattern-print")
      ;;(format t "fix-brd=~a~%" fix-brd)
      (format t "fix-brd=~%")
      (print-mini fix-brd)
      ;;(format t "del-cand-brd=~a~%" del-cand-brd)
      (format t "del-cand-brd=~%")
      (print-mini del-cand-brd)
      (finish-output)
      ) ;; end when

    (return-from find-valid-pattern (values fix-brd del-cand-brd patterns))
    ) ;; end let
  ) ;; end find-valid-pattern

(defun find-valid-pattern-sub (chk-brd coordinate org-check-board)
"[org-check-board]は候補数字が存在する位置だけが[t]であるボード。
返すのは候補数字がナンプレのルール上互いに存在し得るパターンのボードのリスト。

チェックボード[chk-brd]を使って[coordinate]で指定される行・列・ブロックに対する
グループを候補位置から外す。オリジナルのチェックボード[org-check-board]と
比較して存在しなければならない候補範囲に唯一の候補が存在しているかをチェックする。"

  (let (i j brd consistency only-or-no next-coord)

    (when (debug-write-p "find-valid-pattern-sub")
      (format t "chk-brd=~%")
      (print-mini chk-brd)
      (format t "coordinate=~a~%" coordinate)
      ;;(format t "org-chk-brd=~%")
      ;;(print-mini org-check-board)
      ) ;; end when

    ;; ナンプレのルールにより行・列・ブロック内の複数ヶ所に候補数字が存在するならば、
    ;; 確定値は必ずそのどれかでなければならない。
    ;; オリジナルのチェックボード[org-check-board]で候補が存在する行・列・ブロック全てに
    ;; [chk-brd]でも候補が存在すれば[t]、存在しなければ矛盾なので[nil]を返す。
    (setf consistency (candidate-consistency-p org-check-board chk-brd))

    ;; チェックボード[chk-brd]の行・列・ブロックに存在する候補が高々1コかどうかを返す。
    ;; 同じ行・列・ブロックに2個以上の候補が存在するならナンプレのルールに違反。
    ;; 従って、そのような配置パターンでは、全ての位置の候補数字が確定値とはなり得ない。
    ;; 配置パターン全ての位置で候補数字が確定値となり得るパターンを探しているので、
    ;; 同一の行・列・ブロック内に複数の候補が存在すれば[nil]、そうでなければ[t]。
    (setf only-or-no (only-or-no-candidate-p chk-brd))

    (cond
      ((null coordinate)
       nil
       )
      ((and ;; 候補が存在しなければならない行・列・ブロックに候補が存在し、高々1個である。→条件を満たしている。
	consistency
	only-or-no)
       (list chk-brd)
       )
      ((not consistency)
       nil
       )
      ((not only-or-no) ;; 同じ行・列・ブロックのいずれか、または全てに2つ以上の候補位置がある。
       (setf i (first coordinate) j (second coordinate))
       ;;(when (null (aref chk-brd i j))
       ;;  (setf coordinate (next-candidate chk-brd i j))
       ;;  (setf i (first coordinate) j (second coordinate))
       ;; ) ;; end when
       (setf next-coord (next-candidate org-check-board i j)) ;; 「次」の候補数字が存在するセル位置に移動。
       ;; i行j列のセルが属するハウス(グループ)のセルを[nil]にする。
       (setf brd (del-candidate-in-group (new-board chk-brd) i j))
       (cond
	 ;; 「次」のセル位置がもはやないか、「次」のセル位置が次の行以降なら更新した盤面に対して処理を続ける。
         ((or (null next-coord) (> (first next-coord) i))
          (find-valid-pattern-sub brd (next-candidate brd i j) org-check-board))
	 ;; そうでないなら更新した盤面に対して「次」のセル位置から探索した結果に、
	 ;; 現在の盤面の次のセル位置に対して探索した結果を合わせたリストが結果。
         (t (append (find-valid-pattern-sub brd (next-candidate brd i j) org-check-board)
                    (find-valid-pattern-sub chk-brd (next-candidate chk-brd i j) org-check-board)))
	 ) ;; end cond
       )   ;; end (not only-or-no)
      )	   ;; end cond
    )	   ;; end let
  ) ;; end find-valid-pattern-sub

(defun next-candidate (chk-brd row col)
"row行col列より後ろにある次の候補位置を表す行・列のリストを返す。"
  (let (p q idx tmp)
    (setf idx (to-1d-index row col))
    (dotimes (i (- (* *board-size* *board-size*) idx 1))
      (setf tmp (to-2d-index (+ i idx 1)))
      (setf p (first tmp) q (second tmp))
      (if (aref chk-brd p q) (return-from next-candidate (list p q))))
    (return-from next-candidate nil)))

(defun to-1d-index (row col)
"2次元配列の添え字を同じ要素数の1次元配列の添え字に写像する。"
  (+ (* row *board-size*) col))

(defun to-2d-index (idx)
"1次元配列の添え字を同じ要素数の2次元配列の添え字に写像する。"
  (list (floor idx *board-size*) (mod idx *board-size*)))

(defun candidate-consistency-p (org-check-board chk-brd)
"ナンプレのルールにより行・列・ブロック内の複数ヶ所に候補数字が存在するならば、
確定値は必ずそのどれかでなければばならない。

オリジナルのチェックボード[org-check-board]で候補が存在する行・列・ブロック全てに
[chk-brd]でも候補が存在するかどうかを返す。存在しなければ矛盾。"
  (and
   (candidate-consistency-in-row org-check-board chk-brd)
   (candidate-consistency-in-col org-check-board chk-brd)
   (candidate-consistency-in-block org-check-board chk-brd)
   ) ;; end and
  ) ;; end candidate-consistency-p

(defun only-or-no-candidate-p (chk-brd)
"チェックボード[chk-brd]の行・列・ブロックに存在する候補が高々1コかどうかを返す。
ナンプレのルールにより同一の行・列・ブロック内に2個以上の同一候補は存在できない。
従って、そのような配置パターンでは、全ての位置の候補数字が確定値とはなり得ない。

配置パターン全ての位置で候補数字が確定値となり得るパターンを探しているので、
同一の行・列・ブロック内に複数の候補があれば[nil]、そうでなければ[t]。"
  (and
   (only-or-no-candidate-in-rows chk-brd)
   (only-or-no-candidate-in-cols chk-brd)
   (only-or-no-candidate-in-blocks chk-brd)))

(defun candidate-consistency-in-row (check-board chk-brd)
  (let (p q)
    (dotimes (i *board-size*)
      (setf p nil q nil)
      (dotimes (j *board-size*)
        (setf p (or p (aref check-board i j)))
        (setf q (or q (aref chk-brd i j)))
	) ;; end dotimes
      (if (not (equal p q))
	  (return-from candidate-consistency-in-row nil)
	  ) ;; end if
      ) ;; end dotimes
    (return-from candidate-consistency-in-row t)
    ) ;; end let
  ) ;; end candidate-consistency-in-row

(defun only-or-no-candidate-in-rows (chk-brd)
  (let (count)
    (dotimes (i *board-size*)
      (setf count 0)
      (dotimes (j *board-size*)
        (if (aref chk-brd i j) (incf count)))
      (if (> count 1) (return-from only-or-no-candidate-in-rows nil)))
    (return-from only-or-no-candidate-in-rows count)))

(defun candidate-consistency-in-col (check-board chk-brd)
  (let (p q)
    (dotimes (j *board-size*)
      (setf p nil q nil)
      (dotimes (i *board-size*)
        (setf p (or p (aref check-board i j)))
        (setf q (or q (aref chk-brd i j))))
      (if (not (equal p q)) (return-from candidate-consistency-in-col nil)))
    (return-from candidate-consistency-in-col t)))

(defun only-or-no-candidate-in-cols (chk-brd)
  (let (count)
    (dotimes (j *board-size*)
      (setf count 0)
      (dotimes (i *board-size*)
        (if (aref chk-brd i j) (incf count)))
      (if (> count 1) (return-from only-or-no-candidate-in-cols nil)))
    (return-from only-or-no-candidate-in-cols count)))
      
(defun candidate-consistency-in-block (check-board chk-brd)
  (let (p q row col)
    (dotimes (blk-num *board-size*)
      (setf p nil q nil)
      (setf row (block-base-row blk-num)) ;; row-base
      (setf col (block-base-col blk-num)) ;; col-base
      (dotimes (i *block-size*)
        (dotimes (j *block-size*)
          (setf p (or p (aref check-board (+ row i) (+ col j))))
          (setf q (or q (aref chk-brd (+ row i) (+ col j))))))
      (if (not (equal p q)) (return-from candidate-consistency-in-block nil)))
    (return-from candidate-consistency-in-block t)))

(defun only-or-no-candidate-in-blocks (chk-brd)
  (let (count row col)
    (dotimes (blk-num *board-size*)
      (setf count 0)
      (setf row (block-base-row blk-num)) ;; row-base
      (setf col (block-base-col blk-num)) ;; col-base
      (dotimes (i *block-size*)
        (dotimes (j *block-size*)
          (if (aref chk-brd (+ row i) (+ col j)) (incf count))))
      (if (> count 1) (return-from only-or-no-candidate-in-blocks nil)))
    (return-from only-or-no-candidate-in-blocks count)))

(defun do-n-grid (board)
"グリッド解析の実装。

領域[A]と領域[B]の共通領域に候補[k]が存在し、共通領域以外の領域[A]に候補[k]が存在しないなら
共通領域以外の領域[B]にも候補[k]は存在しない。==> 領域[B]から候補[k]を削除して良い。

領域[A]と領域[B]の種類によって以下の手筋に相当。n-gridはx-wing,swordfish等を一般化した
関数でそれらを含む。localizationとtuplesは別関数として実装。singlesはtuplesに含めた。

method              regionA regionB candidate
------------------------------------------------------
singles             row_1   col_1   k_1
                    col_1   row_1   k_1
                    block_1 cell_1  k_1
localization        block_1 row_1   k_1
                    block_1 col_1   k_1
tuples              row_1   col_n   k_n
                    col_1   row_n   k_n
                    block_1 cell_n  k_n
x-wing              row_2   col_2   k_1
swordfish           row_3   col_3   k_1
jellyfish           row_4   col_4   k_1
squirmbag           row_5   col_5   k_1
whale               row_6   col_6   k_1
leviathan           row_7   col_7   k_1
n-grid              row_n   col_n   k_1
------------------------------------------------------
See http://www.stolaf.edu/people/hansonr/sudoku/explain.htm"
  (let (brd info info-list-1 info-list-2 info-list)
    (if (null (easy-check board)) (return-from do-n-grid board))
    (setq info nil)
    (setq info-list-1 nil)
    (setq info-list-2 nil)
    (setf brd (new-board board))
    (loop
       (dotimes (i *board-size*)
         (multiple-value-setq (brd info) (do-n-grid-sub brd (1+ i) 'row))
	 (if info (push info info-list-1))
	 )
       (dotimes (i *board-size*)
         (multiple-value-setq (brd info) (do-n-grid-sub brd (1+ i) 'col))
	 (if info (push info info-list-2))
	 )
       (if (equal-board-p board brd) (return)) ;; exit this loop.
       (setf board (new-board brd))
      ) ;; end loop
    (if info-list-2 (push info-list-2 info-list))
    (if info-list-1 (push info-list-1 info-list))
    (return-from do-n-grid (values (clean-up-board brd) info-list))
    ) ;; end let
  ) ;; end do-n-grid

(defun exec-n-grid (board)
  (let (brd)
    (setf brd (new-board board))
    (setf brd (do-trim brd))
    (setf brd (do-fundamental brd))
    ;;(setf brd (do-cell-unique brd))
    (loop
       (setf brd (do-n-grid brd))
       (if (equal-board-p brd board) (return))
       (setf board (new-board brd)))
    (return-from exec-n-grid brd)))

(defun do-n-grid-sub (brd candidate kind)
  "ボード[brd]に対して候補[candidate]の[kind](行か列)方向のn-gridを探して処理する。"
  (let (grid ncell n-limit candidates blk tsize comblst tuple coordinates brd-addr info-list)
    (setq info-list nil)
    (setf blk (1- candidate)) ;候補[candidate]のグリッド配列でのブロック番号。
    (debug-write "do-n-grid-sub-1" (format nil "候補~dに対する処理をします。" candidate))
    (setf tsize 1)

    (cond
      ((equal kind 'row)                ;グリッド配列を新規作成。
       (setf grid (make-row-grid brd)))
      ((equal kind 'col)
       (setf grid (make-col-grid brd))))

    (loop
      (incf tsize)
      (setf candidates nil)

      (setf ncell 0)			;number of cell.
      (let (cell row col)
        (dotimes (j *board-size*) ;グリッド配列のブロック[blk]に存在する候補を集計。
          (setf row (+ (block-base-row blk) (floor j *block-size*)))
          (setf col (+ (block-base-col blk) (mod j *block-size*)))
          (debug-write "do-n-grid-sub-1"
                       (format nil "(aref grid ~d ~d) ==> ~s" row col (aref grid row col)))
          (setf cell (aref grid row col))
          (when (pure-listp cell)
            (incf ncell)	 ;候補を持つセル数をカウントしておく。
            (push (list (list row col) cell)
                  candidates)
	    ) ;; end when
	  )   ;; end dotimes
	) ;; end let ((([R_1] [C_1]) ([KL_1]))..(([R_n] [C_n]) ([KL_n])) )
      (debug-write "do-n-grid-sub-1" (format nil "ncell=~d" ncell))

      (cond
        ((null (n-grid-limit))
         (setf n-limit ncell)
	 )
        ((integerp (n-grid-limit))
         (setf n-limit (min (n-grid-limit) ncell))
	 )
        (t
	 (error "can't happen. stop at do-n-grid-sub-sub(2).")
	 )
	) ;; end cond

      (if (> tsize n-limit) (return))

      ;;({(([R_1] [C_1]) ([KL_1]))..(([R_r] [C_r]) ([KL_r]))}...)
      (setf comblst (combination candidates tsize))
      (debug-write "do-n-grid-sub-2" (format nil "candidates=~s" candidates))
      (debug-write "do-n-grid-sub-2"
                   (format nil "@@@(combination candidates ~d)=~s" tsize comblst))

      (dolist (comb comblst) ;comb::={(([R_1] [C_1]) ([KL_1]))..(([R_r] [C_r]) ([KL_r]))}
        (setf tuple nil)
        (dolist (cell comb) ;; 選択した[r]組のセル内の候補の和集合。cell::=(([R_1] [C_1]) ([KL_1]))
          (setf tuple (union tuple (second cell)))
	  ) ;; end dolist
        (debug-write "do-n-grid-sub-3" (format nil "comb=~s" comb))
        (debug-write "do-n-grid-sub-3" (format nil "tuple=~s" tuple))

        (when (and tuple (= (length tuple) (length comb))) ;tupleの要素は同盟関係。
          (let (check except cell idx cols target target-addr msg len tmp tmp-2)

            (setf len (length tuple))
            (setf coordinates	     ;グリッド配列上での座標のリスト。
                  (mapcar #'(lambda (x) (first x)) comb)) ;{([R_1] [C_1])..([R_r] [C_r])}
            (setf except (block-except coordinates)) ;gridの対象ブロック内での[coordinates]以外。
            (debug-write "do-n-grid-sub-4" (format nil "coordinates=~s" coordinates))
            (debug-write "do-n-grid-sub-4" (format nil "except=~s" except))

            (setf check nil) ;実際に消去できる候補が存在するかグリッド配列でチェック。
            (dolist (coord except)
              (setf cell (aref grid (first coord) (second coord)))
              (when (pure-listp cell)
                (setf tmp (set-difference cell tuple))
                (if (< (length tmp) (length cell)) (setf check t)) ;消去したとき[check]を[t]に。
                ;;(setf (aref grid (first coord) (second coord)) tmp)
                ) ;; end when
	      )	  ;; end dolist

	    (record-quiz-info :function-name 'do-n-grid)
            (when check			;実際の消去とメッセージ出力。
              (method-applied 'do-n-grid)
              (cond			;プロット情報の登録と出力。
                ((= len 2)
		 (record-quiz-info :explanation "x-wing(2x2)")
                 (plot-info "x-wing(2x2)" *difficulty-n-grid* 11))
                ((= len 3)
		 (record-quiz-info :explanation "swordfish(3x3)")
                 (plot-info "swordfish(3x3)" (* (expt 2 1) *difficulty-n-grid*) 14))
                ((= len 4)
		 (record-quiz-info :explanation "jellyfish(4x4)")
                 (plot-info "jellyfish(4x4)" (* (expt 2 2) *difficulty-n-grid*) 14))
                ((= len 5)
		 (record-quiz-info :explanation "squirmbag(5x5)")
                 (plot-info "squirmbag(5x5)" (* (expt 2 3) *difficulty-n-grid*) 14))
                ((= len 6)
		 (record-quiz-info :explanation "whale(6x6)")
                 (plot-info "whale(6x6)" (* (expt 2 4) *difficulty-n-grid*) 10))
                ((= len 7)
		 (record-quiz-info :explanation "leviathan(7x7)")
                 (plot-info "leviathan(7x7)" (* (expt 2 5) *difficulty-n-grid*) 14))
                ((>= len 8)
                 (setf msg (format nil "n-grid(~dx~d)" len len))
		 (record-quiz-info :explanation msg)
                 (plot-info msg
                            (* (expt 2 (- len 2)) *difficulty-n-grid*)
                            (+ 9 (* (width len) 2))) ))

              (setf brd-addr nil cols nil)
              (dolist (coord coordinates) ;gridを構成するセルのグリッド配列上での各座標を変換。
                (setf cell (aref grid (first coord) (second coord)))
                (setf cols (union (copy-seq cell) cols)) ;ボード上の関連する列番号の和集合。
                (setf idx (+ (* (mod (first coord) *block-size*) *block-size*)
                             (mod (second coord) *block-size*)))
                (dolist (j  cell)  ;ボード上でのセル・アドレスに変換。
                  (if (equal kind 'row)
                      (push (list idx j) brd-addr)
                      (push (list j idx) brd-addr)))) ;[brd-addr]=gridを構成するセル・アドレス。

              (debug-write "do-n-grid-sub-5" (format nil "brd-addr=~s" brd-addr))
              (debug-write "do-n-grid-sub-5" (format nil "cols=~s" cols))

	      (record-quiz-info :position (cons 'cell brd-addr))

              (setf target-addr nil)   ;消去対象となるセル座標を作成。
              (dolist (j cols) ;関連する列内すべてのセル・アドレスを作成。
                (setf target nil)
                (dotimes (i *board-size*)
                  (if (equal kind 'row)
                      (push (list i j) target)
                      (push (list j i) target)))
                (setf target-addr (append target target-addr)))
              (debug-write "do-n-grid-sub-6" (format nil "target-addr(1)=~s" target-addr))
              (setf target target-addr) ;未確定値(候補)が存在するセルだけを残す。
              (setf target-addr nil)
              (dolist (i target)
                (setf tmp (aref brd (first i) (second i)))
                (if (pure-listp tmp) (push i target-addr)))
              (debug-write "do-n-grid-sub-6" (format nil "target-addr(2)=~s" target-addr))
              (setf target-addr
                    (set-difference target-addr brd-addr :test #'equal)) ;グリッド交点は対象外。

              (debug-write "do-n-grid-sub-6" (format nil "target-addr(3)=~s" target-addr))

              (when (>= (mod (explanation-level) 10) 1)
                (let (chk-brd color-brd cand)
                  (setf chk-brd (make-check-board candidate brd))
                  (setf color-brd (new-board brd))
                  ;;(print-depth)
                  (grid-msg len candidate kind)
                  (when (print-check)
                    (dolist (i brd-addr)
		      (setf (aref chk-brd (first i) (second i)) *sharp-mark*)
		      ) ;; end dolist
                    ;;(format t "target-addr = ~s~%" target-addr)
                    (dolist (i target-addr)
                      (setf cand (aref brd (first i) (second i)))
                      (when (and (pure-listp cand) (member candidate cand :test #'=))
                        (setf (aref chk-brd (first i) (second i)) *at-mark*)
			) ;; end when
		      )   ;; end dolist
                    ;; カラーの解説ボードを用意する。
                    (dotimes (i *board-size*)
                      (dotimes (j *board-size*)
                        (setf cell (aref chk-brd i j))
                        (cond
                          ((equal cell *sharp-mark*)
                           (setf color-brd (set-colored-cell color-brd (list i j) 'blue)))
                          ((equal cell *at-mark*)
                           (setf color-brd
                                 (set-colored-candidate
                                  color-brd (list i j) candidate '*elimination-color*))))
                        ) ;;end dotimes
                      )   ;;end dotimes
                    (cond
                      ((and (>= (color-mode) 1) (show-color-board))
                       (print-normal color-brd))
                      (t (print-check-board chk-brd brd)))
                    ) ;; end when
                  )   ;; end let
                )     ;; end when

	      (setq tmp nil)
              (dolist (i target-addr)	;ボード上の候補を消去。
		(setq tmp-2 (aref brd (first i) (second i)))
		(when (and
		       (pure-listp tmp-2)
		       (member candidate tmp-2 :test #'equal)
		       )
		  (setf brd (do-trim-cell candidate brd (first i) (second i)))
		  (push (list 'cannotbe i candidate) tmp)
		  ) ;; end when
		)   ;; end dolist

	      (record-quiz-info :candidate (reverse tmp))
	      (push (record-quiz-info) info-list)
	      (debug-write "do-n-grid-sub-7" (format nil "(record-quiz-info)=~s~%" info-list))
	      (reset-record-quiz-info) 

              ;;(setf brd (do-fundamental (clean-up-board brd))) ;; 2024-01-29
              ;;(if (equal kind 'row) ;ボードを更新したのでグリッド配列も更新。
              ;;    (setf grid (make-row-grid brd))
              ;;    (setf grid (make-col-grid brd)))

              (when (>= (explanation-level) 10)
		(print-board brd)
		) ;; end when
	      )	  ;; end when
	    )	  ;; end let
	  )	  ;; end when
	)	  ;; end dolist
      )		  ;; end loop
    (return-from do-n-grid-sub  (values (clean-up-board brd) info-list))
    ) ;; end let
  )   ;; end do-n-grid-sub

(defun grid-msg (tsize candidate kind)
  (let (msg)
    (cond
      ((equal kind 'row)
       (setf msg "行方向"))
      ((equal kind 'col)
       (setf msg "列方向")))

    (format t "候補[~d]に対して~aに" candidate msg)
    (cond
      ((= tsize 2)
       (format t "x-wing(2x2)="))
      ((= tsize 3)
       (format t "swordfish(3x3)="))
      ((= tsize 4)
       (format t "jellyfish(4x4)="))
      ((= tsize 5)
       (format t "squirmbag(5x5)="))
      ((= tsize 6)
       (format t "whale(6x6)="))
      ((= tsize 7)
       (format t "leviathan(7x7)="))
      ((>= tsize 8)
       (format t "~dx~dのn-grid=" tsize tsize))
      )

    (cond
      ((show-color-board)
       (print-colored-string 'blue (format nil "[~a]" (short-color-name 'blue))))
      (t (format t "[~a]" *sharp-mark*)))
    (format t "が成立しています。~%")
    (cond
      ((show-color-board)
       (print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*))))
      (t (format t "[~a]" *at-mark*)))
    (format t "の位置から[~a]を削除できます。~%" candidate)
    )
  )

;;; 指定した座標[coordinates]を含まない同一行内のすべての座標のリストを返す。
;;; coordinates::=( (R_1 (C_11..C_1n)) (R_2 (C_21..C_2m))... )
(defun rows-except (coordinates)
  (let ((rows nil) (result nil))
    (dolist (k coordinates) (setf rows (union rows (list (first k)))))
    (dotimes (j *board-size*)
      (dolist (i rows)
        (if (not (member (list i j) coordinates :test #'equal)) (push (list i j) result))))
    (return-from rows-except result)))

;;; 指定した座標[coordinates]を含まない同一列内のすべての座標のリストを返す。
;;; coordinates::=( (C_1 (R_11..R_1n)) (C_2 (R_21..R_2m))... )
(defun cols-except (coordinates)
  (let ((cols nil) (result nil))
    (dolist (k coordinates) (setf cols (union cols (list (second k)))))
    (dotimes (i *board-size*)
      (dolist (j cols)
        (if (not (member (list i j) coordinates :test #'equal)) (push (list i j) result))))
    (return-from cols-except result)))

(defun combination (lst r)
"要素の重複がないリスト[lst]の[r]コの要素の組合せを要素とするリストのリストを返す。

(combination '(a b c d e f) 3)
   ==> ((a b c) (a b d) (a b e) (a b f) (a c d) (a c e) (a c f) (a d e) (a d f)
        (a e f) (b c d) (b c e) (b c f) (b d e) (b d f) (b e f) (c d e) (c d f)
        (c e f) (d e f))

(combination '(a b c d e f) 1)
   ==> ((a) (b) (c) (d) (e) (f))

(length (combination '(a b c d e f) 3)) == (comb (length '(a b c d e f)) 3)"
  (cond
    ((> (comb (length lst) r) (expt 10 7))
     (combination3 lst r))
    (t (combination1 lst r))))

(defun comb (n r)
"要素の重複がない[n]個から[r]コの要素を選ぶ選び方の総数を返す。

nCr ::= n!/r!*(n-r)! = n*(n-1)*(n-2)*...*(n-r+1)/r!

ex. (comb 6 3) ==> 20

cl-user> (time (dotimes (i 100000) (comb 150 4)))
Real time: 0.170568 sec.
Run time: 0.168011 sec.
Space: 3200824 Bytes
GC: 3, GC time: 0.0 sec."
  (let (result tmp)
    (cond
      ((zerop r)
       (setf result 1))
      ((= n r)
       (setf result 1))
      (t
       (setf result 1 tmp 1)
       (do ((i n (decf i)))
           ((< i (1+ (- n r))))
         (setf result (* result i)))
       (dotimes (i r) (setf tmp (* tmp (1+ i))))
       (setf result (/ result tmp))))
    (return-from comb result)))

;;; first version.
;;;
;;; Based on the following definition.
;;;
;;;   (comb n 0) = (comb n n) = 1
;;;   (comb n 1) = n
;;;   (comb n r) = (comb n (- n r))
;;;   (comb n r) = (comb (1- n) (1- r)) + (comb (1- n) r)
;;;
;;; cl-user> (time (combination '(a b c d e f g h i j k) 4))
;;; Real time: 8.63E-4 sec.
;;; Run time: 0.0 sec.
;;; Space: 30000 Bytes
;;;
;;; cl-user> (time (progn  (combination1 '(a b c d e f g h i j k l m n o p q r s t u v w x y z) 10) nil))
;;; Real time: 14.332586 sec.
;;; Run time: 14.284892 sec.
;;; Space: 1400678632 Bytes
;;; GC: 19, GC time: 5.680355 sec.
;;;
(defun combination1 (lst r)
  (let (len)
    (setf len (length lst))
    (cond
      ((zerop r) nil)
      ((= r 1) (mapcar 'list lst))
      ((= len r) (list lst))
      ((> r len) nil)
      ((> r (- len r))
       (mapcar #'(lambda (x) (set-difference lst x)) (combination1 lst (- len r))))
      (t (append
          (mapcar #'(lambda (x) (cons (first lst) x)) (combination1 (rest lst) (1- r)))
          (combination1 (rest lst) r)))
      ) ;;end cond
    ) ;;end let
  )
;;;
;;; another version.
;;;
;;; a(0),a(1),...,a(n-1)からr個を選ぶ組み合わせでは
;;;   (a(0),...,a(n-r))   からひとつ
;;;   (a(1),...,a(n-r+1)) からひとつ
;;;   (a(2),...,a(n-r+2)) からひとつ
;;;           :
;;;           :
;;;   (a(r-1),...,a(n-1)) からひとつ
;;; の要素を重複を許さずに選べばよい。重複があった組は捨てる。
;;;
;;; cl-user> (time (combination2 '(a b c d e f g h i j k) 4))
;;; Real time: 0.052161 sec.
;;; Run time: 0.052003 sec.
;;; Space: 568872 Bytes
;;;
(defun combination2 (lst r)
  ;; c-cand for combination's candidate, el-num for number of element's
  (let (len result c-cand num el-num max-num fmt tmp tmp2)
    (if (or (not (integerp r)) (minusp r)) (return-from combination2 nil))
    (setf result nil)
    (setf len (length lst))
    ;; [num]は[el-num]進法での[r]桁の数。
    (setf num 0)
    (setf el-num (1+ (- len r)))
    (setf max-num (1- (expt el-num r)))
    (when (debug-write-p "combination2-1")
      (format t "el-num = ~d~%" el-num)
      (setf fmt (format nil "max-num = ~~~dR" el-num))
      (format t fmt max-num)
      )
    (setf c-cand (make-array r))
    (dotimes (i r)
      (setf (aref c-cand i) (subseq lst i (+ (- len r) i 1)))
      ;;(format t "(aref c-cand ~d) = ~a~%" i (aref c-cand i))
      )
    (cond
      ((< r 0)
       (setf result nil))
      ((> r len)
       (setf result nil))
      ((= r 0)
       (setf result (list lst)))
      ((= r len)
       (setf result (list lst)))
      ((= r 1)
       (setf result (mapcar 'list lst)))
      ((>= r 2)
       (push (subseq lst 0 r) result)
       (loop
          (incf num)
          (if (> num max-num) (return))
          (setf tmp nil)
          (dotimes (i r)
            ;;(format t "(aref c-cand ~d) = ~s~%" i (aref c-cand i))
            (setf tmp2 (nth (digit-of el-num num i) (aref c-cand i)))
            (if (not (member tmp2 tmp :test #'equal)) (push tmp2 tmp))
            ) ;;end dotimes
          (if (= (length tmp) r) (push (sort (copy-seq tmp) #'list-lessp) result))
          ) ;;end loop
       (setf result (unique result))
       )
      ) ;;end cond
    (return-from combination2 (reverse result))))

;;; [p]進法の数[num]の[digit]桁目の数を返す。最も右側の桁をゼロ桁目と数える。
(defun digit-of (p num digit)
  (mod (truncate (/ num (expt p digit))) p))

;;;
;;; more another version.
;;;
;;; (combination '(a b c d e f) 4) はa,b,c,d,e,fの各記号が選択されれば「1」,そうでなければ「0」が
;;; 割り当てられる6桁の2進数を考えれば6桁中4カ所だけが「1」であるような2進数全体に1対1に対応する。つまり
;;;
;;; (a b c d) = #b111100
;;; (a b c e) = #b111010
;;; (a b c f) = #b111001
;;; (a b d e) = #b110110
;;; (a b d f) = #b110101
;;; (a b e f) = #b110011
;;; (a c d e) = #b101110
;;; (a c d f) = #b101101
;;; (a c e f) = #b101011
;;; (a d e f) = #b100111
;;; (b c d e) = #b011110
;;; (b c d f) = #b011101
;;; (b c e f) = #b011011
;;; (b d e f) = #b010111
;;; (c d e f) = #b001111
;;;
;;; cl-user> (setf x nil)
;;; nil
;;; cl-user> (dotimes (i 150) (push i x))
;;; nil
;;; cl-user> x
;;; (149 148 147 146 145 144 143 142 141 140 139 138 137 136 135 134 133 132 131
;;;  130 129 128 127 126 125 124 123 122 121 120 119 118 117 116 115 114 113 112
;;;  111 110 109 108 107 106 105 104 103 102 101 100 99 98 97 96 95 94 93 92 91 90
;;;  89 88 87 86 85 84 83 82 81 80 79 78 77 76 75 74 73 72 71 70 69 68 67 66 65 64
;;;  63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38
;;;  37 36 35 34 33 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12
;;;  11 10 9 8 7 6 5 4 3 2 1 0)
;;;
;;; cl-user> (time (progn (combination{1|3} x r) t))
;;;
;;; ------------------------------------------------------------------------------
;;; (length x) == 150
;;; ------------------------------------------------------------------------------
;;; Speed       combination1            combination3    L:R (time)
;;; ------------------------------------------------------------------------------
;;; r=2  0.001877秒(   1.00)      0.118234秒(   1.00)   1:62.99
;;; r=3  0.255620秒( 136.19)      6.084255秒(  51.46)   1:23.80
;;; r=4 12.360122秒(6585.04)    250.935940秒(2122.37)   1:20.30
;;; ------------------------------------------------------------------------------
;;;
;;; ------------------------------------------------------------------------------
;;; Space       combination1                    combination3            L:R (space)
;;; ------------------------------------------------------------------------------
;;; r=2     447000 Bytes (   1.00)          2682944 Bytes (   1.00)     1:6.00
;;; r=3   35283280 Bytes (  78.93)        196592160 Bytes (  73.27)     1:5.57
;;; r=4 1782916280 Bytes (3988.63)       9622955592 Bytes (3586.72)     1:5.40
;;; ------------------------------------------------------------------------------
;;;
;;; --------------------------------------
;;; n=150       nCr     比率
;;; --------------------------------------
;;; r=2     11175           1.00
;;; r=3    551300          49.33
;;; r=4  20260275        1813.00
;;; r=5 591600030       52939.60
;;; --------------------------------------
;;;
(defun combination3 (lst r)
  (let (len max-num min-num bit-pattern tmp result)
    (setf result nil)
    (setf len (length lst))
    (setf min-num (1- (expt 2 r)))
    (setf max-num (ash min-num (- len r)))
    (cond
      ((< r 0) nil)
      ((> r len) nil)
      ((= r 0) (list lst))
      ((= r len) (list lst))
      ((= r 1) (mapcar 'list lst))
      ((>= r 2)
       (setf result nil)
       (setf bit-pattern min-num)
       (loop
          (setf tmp nil)
          (dotimes (i len)
            (if (logbitp i bit-pattern) (push (nth (- len i 1) lst) tmp))
            )
          (push tmp result)
          (setf bit-pattern (logshift bit-pattern))
          (if (> bit-pattern max-num) (return result))
          ) ;;end loop
       )
      ) ;;end cond
    ) ;;end let
  )

;;;
;;; 重複のない[n]個の要素から[r]個選ぶ組み合わせのリストを[n]ビット中[r]個が１である２進数のリストとして返す。
;;;
;;; cl-user> (setf *print-base* 2)
;;; 10
;;; cl-user> (elemental-combination 5 3)
;;; (11100 11010 11001 10110 10101 10011 1110 1101 1011 111)
;;;
;;; r     |             2               3               4               5
;;; ----------------------------------------------------------------------
;;; n= 50 |     0.007457秒      0.053646秒       0.726779秒     8.675752秒
;;; n=100 |     0.014179秒      0.454879秒      15.784211秒     長時間につき中止
;;; n=150 |     0.031282秒      1.974914秒      94.365670秒     長時間につき中止
;;;
(defun elemental-combination (n r)
  (let (max-num min-num p result)
    ;;(if (or (not (integerp r)) (<= r 0)) (return-from elemental-combination nil))
    (setf result nil)
    (setf min-num (1- (expt 2 r)))
    (setf max-num (ash min-num (- n r)))
    (setf p min-num)
    (loop
       (if (> p max-num) (return))
       (push p result)
       (setf p (logshift p)) )
    (return-from elemental-combination result)))

;;; 引数[lst]から[bit-pattern-list]を元に組み合わせリストを作成して返す。
(defun make-combination-list (lst bit-pattern-list)
  (let (result tmp len)
    (setf len (length lst))
    (setf result nil)
    (dolist (bit-pattern bit-pattern-list)
      (setf tmp nil)
      (dotimes (i len)
        (if (logbitp i bit-pattern) (push (nth (- len i 1) lst) tmp))
        )
      (push tmp result)
      )
    (return-from make-combination-list result)))

;;;
;;; logical shift
;;;
;;; 2進表現での1のビット数が[num]と同じ個数で[num]より大きい最小の整数を返す。
;;; ex. (logshift #b00101101) ==> #b00101110 (bit数が4個で#b00101101より大きい最小の整数は#b00101110)
;;;
;;; cl-user> (time (let (p) (setf p #b1111) (dotimes (i n) (setf p (logshift{1|2} p)))))
;;;
;;; n           1000            10000           100000
;;; -------------------------------------------------------
;;; logshift1   0.002651秒      0.355900秒      280秒で中断
;;; logshift2   0.009127秒      0.041743秒      0.423887秒
;;;
;;; clispでの実験では n=2500付近で実行時間がクロス。このビット長は18ビットに相当。
;;;
(defun logshift (num)
  (cond
    ((< (integer-length num) 18)
     (logshift1 num))
    (t (logshift2 num))))

(defun logshift1 (num)
  (let (bit-num)
    (setf bit-num (logcount num))
    (incf num)
    (loop
       (if (= (logcount num) bit-num) (return))
       (incf num))
    (return-from logshift1 num)))

;;; Mt.Trail@mixiさん提示のアルゴリズムに基ずく関数。
(defun logshift2 (num)
  (let (max-num min-num bit-count bit-width top-bit-num)
    (if (< num 1) (return-from logshift2 0))
    (setf bit-count (logcount num))
    (setf bit-width (integer-length num))
    (setf top-bit-num (expt 2 (1- bit-width)))
    (setf min-num (1- (expt 2 bit-count)))
    (setf max-num (ash min-num (- bit-width (logcount min-num))))
    (cond
      ((= num min-num) ;;最上位ビットを１ビット左シフトした値を返す。
       (logior (ash top-bit-num 1) (logandc1 top-bit-num num)))
      ((< min-num num max-num) ;;最上位ビットと(logshift2 残りビット)の和を返す。
       (logior top-bit-num (logshift2 (logandc1 top-bit-num num))))
      ((= num max-num) ;;最上位ビットを１ビット左シフトした値と残りビットを右詰めした値の和を返す。
       (logior (ash top-bit-num 1) (ash min-num -1)))
      (t (error "can't happen at logshift2"))
      ) ;;end cond
    )
  )

;;
;;
(defun unique (lst &optional (predicate #'equal)) ;; [uniq]より速い。
"引数で与えられたリスト[lst]の要素の重複を取り除いたリストを返す。
cl-user> (length z)
142
cl-user> (time (dotimes (i 1000) (unique z)))
Real time: 1.174955 sec.
Run time: 1.212076 sec.
Space: 2840824 Bytes
GC: 2, GC time: 0.008 sec.

(unique '( 1 2 3 3 4 4 4 5 6 7 7 7 7 7)) ==> (1 2 3 4 5 6 7)"
  (let (result p q)
    (setf result nil)
    (setf p (sort (copy-seq lst) #'list-lessp))
    (loop
       (if (null p) (return))
       (setf q (pop p))
       (if (not (member q result :test predicate)) (push q result)) )
    (return-from unique result)))

;; cl-user> (length z)
;; 142
;; cl-user> (time (dotimes (i 1000) (uniq z)))
;; Real time: 1.597737 sec.
;; Run time: 1.588099 sec.
;; Space: 84616824 Bytes
;; GC: 77, GC time: 0.29201 sec.
;;
;; (uniq '( 1 2 3 3 4 4 4 5 6 7 7 7 7 7)) ==> (1 2 3 4 5 6 7)
;;
;;(defun uniq (lst &optional (predicate #'equal))
;;  (reduce #'(lambda (x y) (union x y :test predicate)) (mapcar 'list lst)))

(defun do-localization (board)
"Localization(=Locked Candidates)の実装。

ブロック内の候補セルが行または列方向だけに直線的に並んでいる場合、並んでいる行
または列内の他候補から並んでいる候補を削除できる。"
  (let (brd info info-list)
    (if (null (easy-check board)) (return-from do-localization board))
    (setf info-list nil)
    (setf brd (new-board board))
    (loop
      (multiple-value-setq (brd info) (do-localization-sub brd))
      (if info (push info info-list))
      (if (equal-board-p brd board) (return))
      (setf board (new-board brd))
      ) ;; end loop
    (return-from do-localization (values brd info-list))
    ) ;; end let
  ) 

(defun exec-localization (board)
  (let (brd)
    (setf brd (new-board board))
    (setf brd (do-trim brd))
    (setf brd (do-fundamental brd))
    ;;(setf brd (do-cell-unique brd))
    (loop
       (setf brd (do-localization brd))
       (if (equal-board-p brd board) (return))
       (setf board (new-board brd)))
    (return-from exec-localization brd)))

(defun do-localization-sub (brd)
  (let (info info-line info-block)
    (setq info-line nil)
    (setq info-block nil)
    (dolist (candidate *np-digit*)
      (dotimes (blk *board-size*)
        ;;When a candidate is possible in a certain block and {row|column},
        ;;and it is not possible anywhere else in the same block,
        ;;then it is also not possible anywhere else in the same {row|column}.
        (setf brd (clean-up-board brd))
        (multiple-value-setq (brd info) (do-localization-line brd blk candidate))
	(debug-write "do-localization-sub-1" (format nil "info=~a" info))
	(if info (setq info-line (append info-line info)))

        ;;When a candidate is possible in a certain block and {row|column},
        ;;and it is not possible anywhere else in the same {row|column},
        ;;then it is also not possible anywhere else in the same block. 
        (setf brd (clean-up-board brd))
        (multiple-value-setq (brd info) (do-localization-block brd blk candidate))
	(debug-write "do-localization-sub-2" (format nil "info=~a" info))
	(if info (setq info-block (append info-block info)))
        ) ;; end dotimes
      )   ;; end dotimes
    (setf brd (clean-up-board brd))

    (cond
      ((and
	(identity info-line)
	(identity info-block))
       (setq info (list info-line info-block))
       )
      ((and
	(identity info-line)
	(null info-block))
       (setq info info-line)
       )
      ((and
	(null info-line)
	(identity info-block))
       (setq info info-block)
       )
      ((and
	(null info-line)
	(null info-block))
       (setq info nil)
       )
      ) ;; end cond

    (return-from do-localization-sub (values brd info))
    )
  )

(defun collect-candidate-in-block (candidate blk brd)
"指定された候補[candidate]を含むブロック[blk]内のセル・アドレスを返す。
返り値 ::= ( (R_1 C_1)...(R_n C_n) ) 同一ブロック内のセル。"
  (let (row-base col-base coord cell)
    (setf row-base (block-base-row blk))
    (setf col-base (block-base-col blk))
    (setf coord nil)
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (setf cell (aref brd (+ row-base i) (+ col-base j)))
        (if (and (listp cell) (member candidate cell))
            (push (list (+ row-base i) (+ col-base j)) coord))))
    (return-from collect-candidate-in-block coord)))

(defun do-localization-block (brd blk candidate)
"ブロック内のあるセルに候補が存在し、ブロック外の同じ行または列にその候補が存在しないなら
その候補はブロック内の他の場所に存在できない。==> ブロック内の他の候補を削除して良い。

サンプル
0:0> 候補[3]=[G]は7列目ではブロック3にのみ存在します。
  ==> ブロック内の他の[3]=[X]を削除できます。
#=======================================================================#
# . . . | . . . | 1 . . # 1 2 3 | 1 2 . | 1 2 3 # . 2 G | . 2 . | . 2 X #
# . 8 . | . 7 . | . 5 . # 4 . . | 4 5 6 | 4 5 6 # . . 6 | . . 6 | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . 9 | . . 9 | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . 3 | 1 . 3 | 1 . . # . . . | 1 2 . | 1 2 3 # . 2 G | . 2 . | . . . #
# . 5 . | . 5 6 | . 5 . # . 9 . | . 5 6 | . 5 6 # . . 6 | . . 6 | . 4 . #
# . . . | . . . | . . . # . . . | 7 . . | . . . # . 8 . | 7 8 . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | . . . # . . . | . . . | . . 3 # . . . | . . . | . . . #
# . . . | . 2 . | . 4 . # . 8 . | . . 6 | . . 6 # . 1 . | . . 6 | . 5 . #
# . . 9 | . . . | . . . # . . . | 7 . . | . . . # . . . | 7 . 9 | . . . #
#=======================#=======================#=======================#
# 1 . . | 1 . . | . . . # . . . | 1 2 . | 1 2 . # . 2 . | . . . | 1 2 . #
# 4 5 . | 4 5 . | . 9 . # . 6 . | 4 . . | 4 . . # . 5 . | . 3 . | . . . #
# 7 . . | . 8 . | . . . # . . . | 7 8 . | . 8 . # . 8 . | . . . | 7 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . 3 | 1 . 3 | 1 2 . # 1 2 . | 1 2 . | 1 2 . # . 2 . | . 2 . | . . . #
# 4 5 . | 4 5 . | . 5 . # 4 . . | 4 . . | 4 . . # . 5 6 | 4 5 6 | . 9 . #
# 7 . . | . 8 . | 7 8 . # 7 . . | 7 8 . | . 8 . # . 8 . | 7 8 . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | 1 . . | . . . # . . . | . . . | 1 2 . # . 2 . | . 2 . | 1 2 . #
# 4 . . | 4 . . | . 6 . # . 5 . | . 3 . | 4 . . # . . . | 4 . . | . . . #
# 7 . . | . 8 . | . . . # . . . | . . . | . 8 9 # . 8 . | 7 8 . | 7 8 . #
#=======================#=======================#=======================#
# . . . | . . . | 1 . . # 1 2 3 | 1 2 . | 1 2 3 # . . . | . 2 . | . 2 3 #
# . 6 . | . 9 . | . 5 . # 4 . . | 4 5 . | 4 5 . # . 7 . | . 5 . | . . . #
# . . . | . . . | . 8 . # . . . | . 8 . | . 8 . # . . . | . 8 . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . . # 1 . 3 | 1 . . | . . . # . . . | . . . | . . 3 #
# . 2 . | . 5 . | . 5 . # . . . | . 5 6 | . 7 . # . 4 . | . 5 6 | . . 6 #
# . . . | . 8 . | . 8 . # . . . | . 8 9 | . . . # . . . | . 8 9 | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . 2 . | . 2 . | . 2 . # . 2 . | . . . | . 2 . #
# 4 5 . | 4 5 . | . 3 . # 4 . . | 4 5 6 | 4 5 6 # . 5 6 | . 1 . | . . 6 #
# 7 . . | . 8 . | . . . # . . . | . 8 9 | . 8 9 # . 8 9 | . . . | . 8 . #
#=======================================================================#

When a candidate is possible in a certain block and row/column,
and it is not possible anywhere else in the same row/column,
then it is also not possible anywhere else in the same block. 

ボード[brd]の[blk]番目のブロックのうち候補[candidate]が存在する座標[coord]を受け取る。
[coord]::=( (R_1 C_1)...(R_n C_n) ) 同一ブロック内のセル。"
  (let (info info-row info-col)
    (setq info nil)
    (multiple-value-setq (brd info-row) (do-localization-block-for brd blk candidate 'row))
    (if info-row (push info-row info))
    (multiple-value-setq (brd info-col) (do-localization-block-for brd blk candidate 'col))
    (if info-col (push info-col info))
    (return-from do-localization-block (values brd info))
    ) ;; end let
  ) ;; end do-localization-block

(defun do-localization-block-for (brd blk candidate kind)
  (let (row-base col-base line line-comp line-union coord target
        mark check chk-brd color-brd cell addr tmp info)

    (setq info nil)

    (when (debug-write-p "do-localization-block-for")
      (format t "(do-localization-block-for brd ~d ~d ~s)~%" (1+ blk) candidate kind)
      (force-output)
      ) ;; end when

    ;;(setf info nil info-list nil)
    (setf row-base (block-base-row blk)) ;ブロック[blk]の左上のコーナーの行アドレス
    (setf col-base (block-base-col blk)) ;ブロック[blk]の左上のコーナーの列アドレス
    
    ;; 候補数字[candidate]が存在するブロック内のアドレスのリスト。[coord]は座標(coordination)の意。
    (setf coord (collect-candidate-in-block candidate blk brd))
    (debug-write "do-localization-for-block" (format nil "coord=~s" coord))

    (dotimes (i *block-size*)
      (if (null coord) (return-from do-localization-block-for brd)) ;候補が存在しないなら終了。

      (setf line nil)
      (cond
        ((equal kind 'row)
         (dolist (k coord) ;; [coord]は候補数字[candidate]が存在するブロック内のアドレスのリスト。
           (push (first k) line)
           ;;(if (not (member (first k)  line :test #'equal)) ;; (member 0 nil :test #'equal) ==> nil
           ;;    (push (first k)  line)
           ;;    ) ;; ブロック内の行番号のユニークなリスト。
           )				      ;; end dolist
         (setf line (sort (unique line) #'<)) ;; sortは処理系による動作の違いを避けるため。2024-01-20
         ) ;; end (equal kind 'row) 
        ((equal kind 'col)
         (dolist (k coord) ;; [coord]は候補数字[candidate]が存在するブロック内のアドレスのリスト。
           (push (second k) line)
           ;;(if (not (member (second k) line :test #'equal)) ;; (member 0 nil :test #'equal) ==> nil
           ;;    (push (second k) line) ;; ブロック内の列番号のユニークなリスト。
           ;;    ) ;; end if
           )				      ;; end dolist
         (setf line (sort (unique line) #'<)) ;; sortは処理系による動作の違いを避けるため。2024-01-20
         )				      ;; end (equal kind 'col)
        (t (error "do-localization-block-for:kind must be row/col.")))

      (cond
        ((equal kind 'row) (setf addr (+ row-base i)))
        ((equal kind 'col) (setf addr (+ col-base i)))
        (t (error "do-localization-block-for:kind must be row/col."))
        ) ;; end cond
      (when (member addr line :test #'equal)
        (cond
          ((equal kind 'row)
           (setf cell (list (+ row-base i) col-base)) ;; ブロック内の該当行のセル・アドレス。
           ;; セル[cell]が属する行のセル・アドレスであって、ブロック内でないアドレスのリスト。
           (setf line-comp (complement-of-block-and-row cell)))
          ((equal kind 'col)
           (setf cell (list row-base (+ col-base i))) ;; ブロック内の該当列のセル・アドレス。
           ;; セル[cell]が属する列のセル・アドレスであって、ブロック内でないアドレスのリスト。
           (setf line-comp (complement-of-block-and-col cell))))

        (setf line-union nil)
        (dolist (n line-comp) ;候補[candidate]が存在する行であってブロック外の候補の和集合。
          (setf tmp (aref brd (first n) (second n)))
          (if (pure-listp tmp) (setf line-union (union line-union tmp)))
          ) ;; end dolist

        (when (null (intersection (list candidate) line-union)) ;成立。

          (setf target nil)
          (cond
            ((equal kind 'row)
             (dolist (k coord) (if (/= (first k)  (first cell))  (push k target))))
            ((equal kind 'col)
             (dolist (k coord) (if (/= (second k) (second cell)) (push k target))))
            ) ;; end cond
          (setf mark (set-difference coord target))

          (setf check nil) ;実際に消去できる候補があるかチェックする。
          (dolist (k target)
            (setf tmp (aref brd (first k) (second k)))
            (if (and (pure-listp tmp) (member candidate tmp)) (setf check t)) ;; 消去できる候補があった。
            ) ;; end dolist

          (when (and check (>= (mod (explanation-level) 10) 1))
            ;;(print-depth)

            (cond
              ((equal kind 'row)
               ;;(format t "候補[~d]=[~a]は~d行目では" candidate *sharp-mark* (+ row-base i 1))
               (format t "候補[~d]=" candidate)
               (cond
                 ((show-color-board)
                  (print-colored-string 'green (format nil "[~a]" (short-color-name 'green) )))
                 (t (format t "[~a]" *sharp-mark*)))
               (format t "は~d行目では" (+ row-base i 1))
	       )

              ((equal kind 'col)
               ;;(format t "候補[~d]=[~a]は~d列目では" candidate *sharp-mark* (+ col-base i 1))
               (format t "候補[~d]=" candidate)
               (cond
                 ((show-color-board)
                  (print-colored-string 'green (format nil "[~a]" (short-color-name 'green))))
                 (t (format t "[~a]" *sharp-mark*)))
               (format t "は~d列目では" (+ col-base i 1))
	       )
              ) ;; end cond
            (format t "ブロック~dにのみ存在します。~%" (1+ blk))
            ;;(tabs (depth))
            (format t "  ==> ")
            ;;(format t "ブロック内の他の[~d]=[~a]を削除できます。~%" candidate *at-mark*)
            (format t "ブロック内の他の[~d]=" candidate)
            (cond
              ((show-color-board)
               (print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*))))
              (t (format t "[~a]" *at-mark*)))
            (format t "を削除できます。~%")

            (when (print-check)
              (setf chk-brd (make-check-board candidate brd))
              (dolist (i mark) (setf (aref chk-brd (first i) (second i)) *sharp-mark*))
              (dolist (i target)
                (setf tmp (aref brd (first i) (second i)))
                (when (and (pure-listp tmp) (member candidate tmp))
                  (setf (aref chk-brd (first i) (second i)) *at-mark*)))
              ;; カラーの解説ボードを用意する。
              (setf color-brd (new-board brd))
              (dotimes (i *board-size*)
                (dotimes (j *board-size*)
                  (setf cell (aref chk-brd i j))
                  (cond
                    ((equal cell *sharp-mark*)
                     (setf color-brd (set-colored-candidate color-brd (list i j) candidate 'green)))
                    ((equal cell *at-mark*)
                     (setf color-brd
                           (set-colored-candidate color-brd (list i j) candidate '*elimination-color*))))
                  ) ;;end dotimes
                )   ;;end dotimes
              (cond
                ((show-color-board)
                 (print-normal color-brd))
                (t (print-check-board chk-brd brd)))
              ) ;; end when
            )   ;; end when

          (when check
            (plot-info "ローカライゼーション(block)" *difficulty-localization* 27)
            (method-applied 'do-localization)
            ) ;; end when

	  ;; [quiz-info-list]のための情報を集める。
	  (when (identity check)
	    (cond
	      ((equal kind 'row)
	       (record-quiz-info :function-name 'do-localization)
	       (record-quiz-info
		:explanation (format nil "行内にひとつ存在しなければならない候補によりブロック内の他候補を削除可"))
	       (record-quiz-info :position (list 'or (list 'block blk) (list 'row (+ row-base i))))
	       (record-quiz-info :candidate (cells-cannotbe-in-block brd blk (+ row-base i) candidate 'row))
	       (push (record-quiz-info) info)
	       (reset-record-quiz-info)
	       ;;(push (list 'do-localization 'unique-in-block-row
	    	;;	   (list 'and (list 'block blk) (list 'row (+ row-base i)))
	    	;;	   (cells-cannotbe-in-block brd blk (+ row-base i) candidate 'row)) info)
	       (debug-write "do-localization-block-for-1" (format nil "info=~a" info))
	       )
	      ((equal kind 'col)
	       (record-quiz-info :function-name 'do-localization)
	       (record-quiz-info
		:explanation (format nil "列内にひとつ存在しなければならない候補によりブロック内の他候補を削除可"))
	       (record-quiz-info :position (list 'or (list 'block blk) (list 'col (+ col-base i))))
	       (record-quiz-info :candidate (cells-cannotbe-in-block brd blk (+ col-base i) candidate 'col))
	       (push (record-quiz-info) info)
	       (reset-record-quiz-info)
	       ;;(push (list 'do-localization 'unique-in-block-col
	    	;;	   (list 'and (list 'block blk) (list 'col (+ col-base i)))
	    	;;	   (cells-cannotbe-in-block brd blk (+ col-base i) candidate 'col) info)
	       (debug-write "do-localization-block-for-2" (format nil "info=~a" info))
	       )
	      ) ;; end cond
	    ) ;; end when

          (dolist (k target) ;; 実際に消去。
            (setf brd (do-trim-cell candidate brd (first k) (second k)))
            ) ;; end dolist
          (setf brd (clean-up-board brd))
          (when (and check (>= (explanation-level) 10))
            (print-board brd)
            ) ;; end when
          ;;(setf coord (collect-candidate-in-block candidate blk brd))
          ) ;; end (when (null (intersection (list candidate) line-union))
        )   ;; end (when (member addr line)
      )     ;; end (dotimes i *block-size*)
    (return-from do-localization-block-for (values brd info))
    ) ;; end let
  ) ;; end do-localization-block-for

(defun complement-of-block-and-row (cell)
  "セル[cell]が属する行のセル・アドレスであって、ブロック内でないアドレスのリストを返す。
[cell] ::= (row col)
返り値 ::= (行アドレスのリスト)"
  (let (blk col-base block-and-row row-list)
    (setf blk (block-num (first cell) (second cell)))
    (setf col-base (block-base-col blk))
    (setf block-and-row nil)
    (dotimes (j *block-size*)
      (push (list (first cell) (+ col-base j)) block-and-row))
    (setf row-list (row-except block-and-row))
    (return-from complement-of-block-and-row row-list)
    ) ;; end let
  ) ;; end defun

(defun cells-cannotbe (brd cell-addr-list candidate)
  "セル・アドレスのリスト[cell-addr-list]に対して(and (cannotbe cell-1 ([candidate]))...)という
リストを作って返す。[cell-addr-list]が[nil]なら[nil]を返す。"
  (let (result tmp)
    (setq result nil)
    (setq tmp nil)
    (if (null cell-addr-list) (return-from cells-cannotbe nil))
    (dolist (p cell-addr-list)
      (setq tmp (aref brd (first p) (second p)))
      (if (and (pure-listp tmp) (member candidate tmp :test #'=)) (push p result))
      ) ;; end dolist
    (setq tmp nil)
    (dolist (p (sort (copy-seq result) #'cell-order-p))
      (cond
	((pure-listp candidate)
	 (push (list 'cannotbe p candidate) tmp)
	 )
	(t
	 (push (list 'cannotbe p (list candidate)) tmp)
	 )
	)
      ) ;; end dolist
    (if (null tmp) (return-from cells-cannotbe nil))
    ;;(return-from cells-cannotbe (cons 'and (reverse tmp)))
    (return-from cells-cannotbe (reverse tmp))
    ) ;; end let
  ) ;; end cells-cannotbe


(defun cells-cannotbe-in-block (brd blk-num row-or-col candidate direction)
  "ブロック[blk]で行/列[row-or-col]以外で候補数字[candidate]を含むセル・アドレスの削除/確定情報のリストを返す。
ex. (cannotbe brd 0 0 2 'row) ==> (and (cannotbe (1 0) 2) (cannotbe (2 0) 2))"
  (let (result line-cells)
    (cond
      ((equal direction 'row)
       (setq line-cells (same-row-cells-for-row row-or-col)) ;; row
       )
      ((equal direction 'col)
       (setq line-cells (same-col-cells-for-col row-or-col)) ;; col
       )
      (t
       (error "function cells-cannotbe-in-block : fourth parameter must be \'row or \'col.~%")
       )
      ) ;; end cond
    ;; set-differenceはブロック[blk-num]であって行/列[row-or-col]でないセル・アドレスのリスト。
    (setq result
	  (cells-cannotbe brd (set-difference (same-block-cells-for-block blk-num) line-cells :test #'equal)
			  candidate))
    (return-from cells-cannotbe-in-block result)
    ) ;; end let
  ) ;; end cannotbe

(defun cannotbe-list (cell-addr candidate-list)
  "(cannotbe ([row] [col]) (cand-1 cand-2 ... cand-n))というリストを作って返す。
ex. (cannotbe-list '(0 0) '(1 3 4 7 8)) ==> (cannotbe (0 0) (1 3 4 7 8))"
  (if (integerp candidate-list)
      (return-from cannotbe-list (list 'cannotbe cell-addr (list candidate-list))))
  (return-from cannotbe-list (list 'cannotbe cell-addr candidate-list))
  )

(defun complement-of-block-and-col (cell)
"セル[cell]が属する列のセル・アドレスであって、ブロック内でないアドレスのリストを返す。
[cell] ::= (row col)
返り値 ::= (列アドレスのリスト)"
  (let (blk row-base  block-and-col col-list)
    (setf blk (block-num (first cell) (second cell)))
    (setf row-base (block-base-row blk))
    (setf block-and-col nil)
    (dotimes (i *block-size*)
      (push (list (+ row-base i) (second cell)) block-and-col))
    (setf col-list (col-except block-and-col))
    (return-from complement-of-block-and-col col-list)))

(defun do-localization-line (board blk candidate)
  "ブロック内の候補セルが行または列方向だけに直線的に並んでいる場合、その候補セルのいずれかが確定値。
従って、ブロック外の同じ行または列内の他候補を削除できる。
"
  (let (brd row-line col-line coord info elimination-pos)
    (setf brd (new-board board))
    ;;指定された候補[candidate]を含むブロック[blk]内のセル・アドレスを返す。
    (setf coord (collect-candidate-in-block candidate blk brd))
    (setf row-line (same-row-only coord))
    (setf col-line (same-col-only coord))
    (setf info nil)
    (when (debug-write-p "do-localization-line-1")
      (format t "candidate=~d, block=~d~%" candidate blk)
      (format t "coord=~s~%" coord)
      (format t "row-line=~d~%" row-line)
      (format t "col-line=~d~%" col-line))
    (when (and (>= (length coord) 2) (or row-line col-line)) ;成立。
      (debug-write "do-localization-line" (format nil "成立しました。削除可能な候補を探します。"))
      (let (check lst except chk-brd color-brd cand)
        (setf except nil) ;行または列方向の対象セルのリストを作成する。
        (dotimes (k *board-size*)
          (cond
            (row-line
             (if (and (pure-listp (aref brd row-line k))
                      (not (member (list row-line k) coord :test 'equal)))
                 (push (list row-line k) except)))
            (col-line
             (if (and (pure-listp (aref brd k col-line))
                      (not (member (list k col-line) coord :test 'equal)))
                 (push (list k col-line) except)))
            (t (error "can't happen at do-localization."))))
        (debug-write "do-localization-line" (format nil "except=~s" except))
        (setf check nil) ;実際に削除できる候補がある場合だけ表示する。
        (dolist (i except)
          (setf lst (aref brd (first i) (second i)))
          (debug-write "do-localization-line-2"
                       (format nil "(aref brd ~d ~d)=~s" (first i) (second i) lst))
          (if (and (pure-listp lst) (member candidate lst)) (setf check t)))
        (debug-write "do-localization-line-3" (format nil "check=~s" check))
        (when (and check (>= (mod (explanation-level) 10) 1))
          (setf chk-brd (make-check-board candidate brd))
          ;;(print-depth)
          ;;(format t "ブロック~dの候補[~d]=[~a]に対して" (1+ blk) candidate *sharp-mark*)
          (format t "ブロック~dの候補[~d]=" (1+ blk) candidate)
          (cond
            ((show-color-board)
             (print-colored-string 'green (format nil "[~a]" (short-color-name 'green))))
            (t (format t "[~a]" *sharp-mark*)))
          (format t "は全ての候補がブロック内で直線上に並んでいます。~%")
          ;;(tabs (depth))
          (format t "  ==> ブロック外の同じ直線上の")
          (cond
            ((show-color-board)
             (print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*))))
            (t (format t "[~a]" *at-mark*)))
          (format t "の位置から[~d]を削除できます。~%" candidate)
          (when (print-check)
            (setf chk-brd (make-check-board candidate brd))
            (dolist (i coord) (setf (aref chk-brd (first i) (second i)) *sharp-mark*))
            ;;(format t "except = ~s~%" except)
            (dolist (i except)
              (setf cand (aref brd (first i) (second i)))
              (when (and (pure-listp cand) (member candidate cand :test #'=))
                (setf (aref chk-brd (first i) (second i)) *at-mark*)))

            ;; [color-brd]を用意する。
	    (setf elimination-pos nil)
            (setf color-brd (new-board brd))
            (dotimes (i *board-size*)
              (dotimes (j *board-size*)
                (setf cand (aref chk-brd i j))
                (cond
                  ((equal cand *sharp-mark*)
                   (setf color-brd (set-colored-candidate color-brd (list i j) candidate 'green)))
                  ((equal cand *at-mark*)
		   (push (list i j) elimination-pos) ;; 2024-02-28
                   (setf color-brd
                         (set-colored-candidate color-brd (list i j) candidate '*elimination-color*)))
		  ) ;; end cond
		) ;; end dotimes
	      ) ;; end dotimes
            
	    (when
		(and
		 (>= (length coord) 2)
		 (identity row-line)
		 (identity check)
		 )
	      (record-quiz-info :function-name 'do-localization)
	      (record-quiz-info :explanation (format nil "行上の候補がブロック内で唯一"))
	      (record-quiz-info :position (list 'and (list 'block blk) (list 'row row-line)))
	      (record-quiz-info :candidate (cells-cannotbe brd elimination-pos candidate))
	      (push (record-quiz-info) info)
	      (reset-record-quiz-info)
	      ;;(push (list 'do-localization 'row-line-in-block
		;;	  (list 'and (list 'block blk) (list 'row row-line))
		;;	  (cells-cannotbe brd elimination-pos candidate)) info)
	      (debug-write "do-localization-line-1" (format nil "info=~a" info))
	      ) ;; end when

	    (when
		(and
		 (>= (length coord) 2)
		 (identity col-line)
		 (identity check)
		 )
	      (record-quiz-info :function-name 'do-localization)
	      (record-quiz-info :explanation (format nil "列上の候補がブロック内で唯一"))
	      (record-quiz-info :position (list 'and (list 'block blk) (list 'col col-line)))
	      (record-quiz-info :candidate (cells-cannotbe brd elimination-pos candidate))
	      (push (record-quiz-info) info)
	      (reset-record-quiz-info)
	      ;;(push (list 'do-localization 'col-line-in-block
		;;	  (list 'and (list 'block blk) (list 'col col-line))
		;;	  (cells-cannotbe brd elimination-pos candidate)) info)
	      (debug-write "do-localization-line-2" (format nil "info=~a" info))
	      ) ;; end when

            (cond
              ((show-color-board)
               (print-normal color-brd))
              (t (print-check-board chk-brd brd))) ))

        (when check
          (plot-info "ローカライゼーション(row/col)" *difficulty-localization* 29)
          (method-applied 'do-localization)
          (dolist (i except)
            (setf brd (do-trim-cell candidate brd (first i) (second i)))) )
        (when (and check (>= (explanation-level) 10)) (print-board brd))
	) ;; end second let
      )	  ;; end first when
    (debug-write "do-localization-line" (format nil "returns ~a~%~a" (clean-up-board brd) info))
    (return-from do-localization-line (values (clean-up-board brd) info))
    ) ;; end let
  ) ;; end do-localization-line

(defun same-row-only (coordinates)
"指定された ((行1 列1) (行2 列2) ... ) というリストのすべての 行1..行n が同じ値なら
その値を返す。そうでないなら[nil]を返す。"
  (let ((n nil))
    (when coordinates
      (setf n (first (first coordinates)))
      (dolist (i (rest coordinates)) (if (not (equal (first i) n)) (setf n nil))))
    (return-from same-row-only n)))

(defun same-col-only (coordinates)
"指定された ((行1 列1) (行2 列2) ... ) というリストのすべての 列1..列n が同じ値なら
その値を返す。そうでないなら[nil]を返す。"
  (let ((n nil))
    (when coordinates
      (setf n (second (first coordinates)))
      (dolist (i (rest coordinates)) (if (not (equal (second i) n)) (setf n nil))))
    (return-from same-col-only n)))

(defun same-block-only (coordinates)
"指定された ((行1 列1) (行2 列2) ... ) というリストのすべてが同じブロックに属すなら
そのブロック番号を返す。そうでないなら[nil]を返す。"
  (let (blk-num)
    (when coordinates
      (setf blk-num (block-num (first (first coordinates)) (second (first coordinates))))
      (dolist (i (rest coordinates))
        (if (not (equal (block-num (first i) (second i)) blk-num)) (setf blk-num nil))))
    (return-from same-block-only blk-num)))

(defun make-col-grid (board)
"候補[m]が[j]列の何行目に存在しているかをブロック[m]の[j]番目のセルに記録する(確定値は対象外)。
[m] ::= [*np-digit*の要素] ; 9x9のナンプレでは 1..9。
[j] ::= 1..[*board-size*]  ; 9x9のナンプレでは 1..9。
[行数] ::= 0..(1- *board-size*) ; 9x9のナンプレでは 0..8 ;

Example : オリジナル・ボード(als-01)
#=======================================================================#
# . . . | . . . | . . . # . . 3 | . . 3 | . . . # . . . | . . . | . . . # 
# . 2 . | . 6 . | . 4 . # . . . | . . . | . 8 . # . 1 . | . 5 . | . 9 . # 
# . . . | . . . | . . . # 7 . . | 7 . . | . . . # . . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . 3 | . . 3 # 
# . 1 . | . 5 . | . 5 . # . 4 . | . 2 . | . 6 . # . . . | . . . | . . . # 
# . . . | . . 9 | . . 9 # . . . | . . . | . . . # 7 8 . | 7 8 . | 7 8 . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | . . 3 # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | . . . | . . . # . 5 . | . 1 . | . 9 . # . 6 . | . 4 . | . 2 . # 
# . 8 . | 7 8 . | 7 8 . # . . . | . . . | . . . # . . . | . . . | . . . # 
#=======================#=======================#=======================#
# . . . | . . . | 1 . . # . . . | . . . | 1 . . # . . . | . . . | . . . # 
# . 4 . | . . . | . . . # . 2 . | . 5 . | . . . # . 3 . | . . . | . 6 . # 
# . . . | 7 8 9 | 7 8 . # . . . | . . . | 7 . . # . . . | . 8 9 | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | 1 2 . # . . . | . . . | 1 . . # . . . | . 2 . | . . . # 
# . 5 . | . 3 . | . 5 . # . 6 . | . 8 . | . . . # . 4 . | . . . | . 5 . # 
# . . 9 | . . . | 7 . 9 # . . . | . . . | 7 . . # . . . | 7 . 9 | 7 . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . 2 . | . . . # . . . | . . . | . . . # . 2 . | 1 2 . | 1 . . # 
# . 5 . | . 5 . | . 6 . # . 9 . | . 4 . | . 3 . # . 5 . | . . . | . 5 . # 
# . 8 . | 7 . . | . . . # . . . | . . . | . . . # 7 8 . | 7 8 . | 7 8 . # 
#=======================#=======================#=======================#
# . . 3 | . 2 . | . 2 3 # . . . | . . 3 | . 2 . # . 2 . | . . . | . . . # 
# . 5 . | . 5 . | . 5 . # . 1 . | . . . | . 5 . # . 5 . | . 6 . | . 4 . # 
# . 8 9 | . 8 9 | . 8 9 # . . . | 7 . 9 | . . . # 7 8 9 | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . 2 3 # . . 3 | . . . | . . . # . 2 . | . 2 3 | . . 3 # 
# . 7 . | . 1 . | . 5 . # . . . | . 6 . | . 4 . # . 5 . | . . . | . 5 . # 
# . . . | . . . | . 8 9 # . 8 . | . . . | . . . # . 8 9 | . 8 . | . 8 . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . 2 3 # . . 3 | . . 3 | . 2 . # . 2 . | 1 . 3 | 1 . 3 # 
# . 6 . | . 4 . | . 5 . # . . . | . . . | . 5 . # . 5 . | . . . | . 5 . # 
# . . . | . . . | . 8 9 # 7 8 . | 7 . 9 | . . . # 7 8 9 | 7 8 . | 7 8 . #
#=======================================================================#

col-grid board
[1]は3列目の3 native行目(=左上を1行1列とする数え方で4行目)と4 native行目(=5行目)にある。
[1]は6列目の3 native行目(=左上を1行1列とする数え方で4行目)と4 native行目(=5行目)にある。
[1]は8列目の5 native行目(=左上を1行1列とする数え方で6行目)と8 native行目(=9行目)にある。
[1]は9列目の5 native行目(=左上を1行1列とする数え方で6行目)と8 native行目(=9行目)にある。
以下同様。

#=======================================================================#
# . . . | . . . | . . 3 # . . . | . . . | . . . # . 2 . | . . . | . 2 . # 
# . . . | . . . | 4 . . # . . . | . 5 6 | 4 . 6 # . . 6 | . . . | . . 6 # 
# . . . | . . . | . . . # . . . | . . . | 7 8 . # . . . | . . . | 7 8 . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . 3 # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | . . . | 4 . . # . . . | . . . | . . 6 # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . 8 . # . . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | 1 . . | 1 . . # 
# . . . | . 5 . | . 5 . # . 5 6 | 4 5 . | . . . # . . . | . . . | . . . # 
# . . . | . 8 . | . 8 . # 7 8 . | 7 . . | . . . # . . . | 7 8 . | 7 8 . # 
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | 1 . . | 1 . . # . . . | . . . | . . . # 
# . . . | . . . | . . . # 4 5 6 | . 5 6 | 4 . 6 # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | 7 8 . # . . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . . 6 # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . 8 . # . . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | . . . | . . . # . 5 6 | . . . | 4 5 . # . . . | . . . | . . . # 
# . . . | . . . | . . . # 7 8 . | . . . | 7 8 . # . . . | . . . | . . . # 
#=======================#=======================#=======================#
# . . . | . 2 3 | . 2 3 # . 2 . | . 2 3 | . 2 3 # . . . | 1 . 3 | 1 . . # 
# . . . | . 5 . | 4 . . # . 5 6 | . . 6 | . . 6 # 4 . 6 | . . 6 | 4 . 6 # 
# . . . | . . . | . . . # . . . | . . . | 7 8 . # . . . | . . . | 7 8 . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . 3 # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | . . . | 4 . . # . . . | . . . | . . . # . . . | . . 6 | . . . # 
# . . . | . . . | . . . # 7 8 . | . . . | . . . # . . . | . 8 . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | 1 . . | 1 . . # 1 . . | 1 . 3 | 1 . . # . . . | . . 3 | . . . # 
# . 5 6 | 4 5 . | 4 5 . # . 5 6 | . 5 . | . 5 . # . . 6 | 4 . . | . . . # 
# . 8 . | . 8 . | . 8 . # 7 8 . | 7 8 . | 7 8 . # 7 8 . | . . . | . . . #
#=======================================================================#

make-col-gridが作成する表とmake-row-gridが作成する表は本質的には同じ。"
  (let (ga-board coordinate)            ;grid-analysis board
    (setf ga-board (make-array (list *board-size* *board-size*) :initial-element nil))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (when (pure-listp (aref board i j))
          (dolist (candidate (aref board i j))
            (setf coordinate (grid-coordinate i j candidate))
            (push (third coordinate) (aref ga-board (first coordinate) (second coordinate)))))))
    (return-from make-col-grid ga-board)))


(defun make-row-grid (board)
"候補[m]が[i]行の何列目に存在しているかをブロック[m]の[i]番目のセルに記録する(確定値は対象外)。

Example : row-grid board (オリジナル・ボードは[make-col-grid]の例と同じ)
#=======================================================================#
# . . . | . . . | . . . # . . . | . . . | . . . # . . 3 | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . . . # 4 . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | 7 8 . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . 2 . | . . . # . . . | . 2 . | 1 . . # . . . | . . . | . . . # 
# . 5 . | . 5 . | . . . # . . . | . . . | . . 6 # . . . | . . . | . . . # 
# . . . | . . . | 7 8 . # . . . | 7 . . | 7 . . # . . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # 1 2 . | . 2 . | . 2 . # . . . | . 2 3 | . 2 3 # 
# . . . | . . . | . . . # . 5 6 | . . 6 | . 5 6 # . . . | . . . | 4 . . # 
# . . . | . . . | 7 8 . # . . . | 7 . . | . . . # . . . | 7 8 . | 7 8 . # 
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | 1 2 . | . . . # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . 2 . | . 2 . # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . . 6 | . 5 6 # . . . | . . . | . . . # 
# . . . | . . . | . . . # . . . | . 8 . | . 8 . # . . . | . . . | . . . # 
#=======================#=======================#=======================#
# . . 3 | . . . | 1 2 . # . . . | . . . | . . . # . . . | 1 2 . | . . . # 
# 4 . . | . . 6 | . . . # . . . | . . 6 | . . . # . . . | . . . | . . . # 
# . . . | 7 8 . | . . . # . . . | 7 8 . | . . . # . . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 2 . | . 2 . | 1 . . # 1 2 . | . . . | . . . # 1 . . | . . . | . . . # 
# . 5 . | . 5 . | . . 6 # . . . | . . . | . . . # . . . | . . . | . . . # 
# . . . | 7 8 . | 7 8 . # 7 . . | . . . | . . . # 7 . . | . . . | . . . # 
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . 3 # . . . | . 2 3 | . 2 3 # . . . | . 2 . | . 2 . # 
# 4 . 6 | . . . | 4 . 6 # . . . | . . 6 | . . 6 # . . . | . . 6 | 4 . 6 # 
# . . . | . . . | 7 8 . # . . . | 7 8 . | 7 8 . # . . . | . . . | . . . #
#=======================================================================#

make-col-gridが作成する表とmake-row-gridが作成する表は本質的には同じ。"
  (let (ga-board coordinate)            ;grid-analysis board
    (setf ga-board (make-array (list *board-size* *board-size*) :initial-element nil))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (when (pure-listp (aref board i j))
          (dolist (candidate (aref board i j))
            (setf coordinate (grid-coordinate j i candidate))
            (push (third coordinate) (aref ga-board (first coordinate) (second coordinate)))))))
    (return-from make-row-grid ga-board)))

(defun grid-coordinate (i j candidate)
"[i]行[j]列の候補[candidate]をグリッド解析用配列に記録するための情報を返す。
返される情報は ([行番号] [列番号] [追加用データ])。行番号と列番号を逆に与
えれば候補[candidate]が何行目の何列目に存在しているかという情報になる。

この情報を使って
    (push [追加用データ] (aref [グリッド解析用配列] [行番号] [列番号])) 
とする。"
  (let (row-base col-base row col blk-num)
    (setf blk-num (1- candidate))
    (setf row-base (block-base-row blk-num)) ;; row-base
    (setf col-base (block-base-col blk-num)) ;; col-base
    (setf row (floor j *block-size*))
    (setf col (mod j *block-size*))
    (return-from grid-coordinate (list (+ row-base row) (+ col-base col) i))))

(defun count-cell-in-grid (candidate grid)
"グリッド解析用配列[grid]の[candidate]ブロックの[nil]でないセル数を返す。"
  (let ((count 0) row col)
    (setf row (block-base-row (1- candidate)))  ;; row-base
    (setf col (block-base-col (1- candidate)))  ;; col-base
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (if (aref grid (+ row i) (+ col j)) (incf count))))
    (return-from count-cell-in-grid count)))

(defun do-n-tuples (board)
"tuples(n国同盟)の実装。n=2の場合がpair、n=3の場合がtriple,...。

hidden tuples:
行・列またはブロック内で[n]種の候補を含むセルが[n]カ所あり、他のセルにはその[n]種の候補が
存在しないのであれば、それらのセルにはその[n]種の候補以外は存在できない。==>他候補を削除。

hidden-tuples適用後のセルには必ずnaked-tuplesを適用できる。

naked tuples:
行・列またはブロック内で[n]コの候補だけからなるセルが[n]カ所あれば、この[n]コの候補は
この[n]カ所のセル以外には存在できない。==>削除してよい。"
  (let (brd info-list)
    (setf brd (new-board board))        ;make room.
    (multiple-value-setq (brd info-list) (do-tuples brd))
    (return-from do-n-tuples (values brd (list info-list)))
    ) ;; end let
  ) ;; end do-n-tuples

(defun do-tuples (board)
  (let (p q r info-list tmp)
    (if (null (easy-check board)) (return-from do-tuples (values board nil)))
    (setq info-list nil)
    (multiple-value-setq (p tmp) (do-tuples-row (new-board board)))
    (if (identity tmp) (push tmp info-list))
    (multiple-value-setq (q tmp) (do-tuples-col (new-board p)))
    (if (identity tmp) (push tmp info-list))
    (multiple-value-setq (r tmp) (do-tuples-block (new-board q)))
    (if (identity tmp) (push tmp info-list))
    (debug-write "do-tuples-1" (format nil "info-list=~a~%" info-list))
    (return-from do-tuples (values r (reverse info-list)))
    ) ;; end let
  ) ;; end do-tuples

(defun exec-n-tuples (board)
  (let (brd)
    (setf brd (new-board board))
    (setf brd (do-trim brd))
    (setf brd (do-fundamental brd))
    ;;(setf brd (do-cell-unique brd))
    (loop
       (setf brd (do-n-tuples brd))
       (if (equal-board-p brd board) (return))
       (setf board (new-board brd)))
    (return-from exec-n-tuples brd)))

(defun do-tuples-row (board)
  (let (brd info-list)
    (multiple-value-setq (brd info-list) (do-tuples-sub board 'row))
    (return-from do-tuples-row (values brd info-list))
    ) ;; end let
  ) ;; end do-tuples-row

(defun do-tuples-col (board)
  (let (brd info-list)
    (multiple-value-setq (brd info-list) (do-tuples-sub board 'col))
    (return-from do-tuples-col (values brd info-list))
    ) ;; end let
  ) ;; end do-tuples-col

(defun do-tuples-block (board)
  (let (brd info-list)
    (multiple-value-setq (brd info-list) (do-tuples-sub board 'block))
    (return-from do-tuples-block (values brd info-list))
    ) ;; end let
  ) ;; end do-tuples-block

(defun do-tuples-sub (board kind)
  (let (brd n n-limit coordinates candidates comblst quiz-info)
    (setf brd (new-board board))
    (reset-record-quiz-info)
    (setq quiz-info nil)
    (dotimes (i *board-size*)
      (debug-write "do-tuples" (format nil "~%~s ~dを処理します" kind i))
      (setq n 0)
      (setq candidates nil)
      (let (cand row col)
        (dotimes (j *board-size*) ;[i]行[j]列/[j]行[i]列/ブロック[i]#[j]に存在する候補を集計。
          (cond
            ((equal kind 'row)
             (setq row i)
             (setq col j))
            ((equal kind 'col)
             (setq row j)
             (setq col i))
            ((equal kind 'block)
             (setq row (+ (block-base-row i) (floor j *block-size*)))
             (setq col (+ (block-base-col i) (mod j *block-size*))))
            (t (error "can't happen. stop at do-tuples-sub(1).")))
          (debug-write "do-tuples" (format nil "row=~d, col=~d" row col))
          (setf cand (aref brd row col))
          (when (and (pure-listp cand) (>= (length cand) 2)) ;; 確定値なのにリスト形式だった場合の備え。
            (incf n) ;; 候補を持つセル数をカウントしておく。
	    ;;((([C_1] [R_1]) ([KL_1]))..(([C_n] [R_n]) ([KL_n])) )
            (push (list (list row col) cand) candidates) ;; 候補数字を持つセルの全体。
	    )						 ;; end when
	  ) ;; end dotimes
	)   ;; end let
      (debug-write "do-tuples" (format nil "candidates=~s" candidates))

      (cond
        ((null (tuples-limit))
         (setf n-limit n))
        ((integerp (tuples-limit))
         (setf n-limit (min (tuples-limit) n)))
        (t (error "can't happen. stop at do-tuples-sub(2)."))
	) ;; end cond

      (do ((r 1 (incf r)))
	  ((> r n-limit))
	;; 候補を持つセル全体からr個の組み合わせを要素とするリストのリストを得る。
        ;;comblst::=( ((([R_1] [C_1]) ([KL_1]))..(([R_r] [C_r]) ([KL_r])))+ )
        (setf comblst (combination candidates r))
        (debug-write "do-tuples" (format nil "r=~d, comblst=~s" r comblst))
        (let (subset complement tuples sorted-tuple)
          (dolist (comb comblst) ;comb::={(([R_1] [C_1]) ([KL_1]))..(([R_r] [C_r]) ([KL_r]))}
            (setf subset nil)
            (dolist (cell comb)	;; cell::=(([R_1] [C_1]) ([KL_1]))
              (setf subset (union subset (second cell)))
	      ) ;; [subset] ::= 選択した[r]組のセル内の候補の和集合を得る。
            (setf complement nil) ;選択した[r]組以外のセル内の候補の和集合。
            (dolist (k candidates) ;; [candidates]は2つ以上の候補数字を持つセルと候補数字の組の全体。
              (if (not (member k comb :test #'equal)) ;; r組のセルのリストに含まれないセル。
                  (setf complement (union complement (second k))) ;; 上記セルの候補数字の全体を集める。
		  ) ;; end if
	      )	    ;; end dolist
            (setf tuples (combination subset r)) ;([r]組のセル内の候補の和集合)から[r]コ選ぶ組合せのリスト。

            (dolist (tuple tuples)
              (setf sorted-tuple (sort (copy-list tuple) #'<))
              (when (and complement (null (intersection tuple complement))) ;tupleの要素は同盟関係。
                (setf coordinates (mapcar #'(lambda (x) (first x)) comb)) ;hidden tuplesの対象座標。
                (debug-write "do-tuples-tuple" (format nil "tuple=~s" tuple))
                (debug-write "do-tuples-candidates" (format nil "coordinates=~s" coordinates))
                (let (check chk-brd color-brd except msg cells cand row col
		      intersection-of-tuple-and-candidate cannotbe-candidate)
                  (setf check nil)
                  (setf color-brd (new-board board))

                  (cond	;; hidden tuplesの対象座標以外の座標。
                    ((equal kind 'row)
                     (setf except (row-except coordinates)))
                    ((equal kind 'col)
                     (setf except (col-except coordinates)))
                    ((equal kind 'block)
                     (setf except (block-except coordinates)))
                    (t (error "can't happen. stop at do-tuples-sub(3).")))
                  (debug-write "do-tuples" (format nil "except=~s" except))

                  (dolist (coord coordinates) ;hidden tuplesに対する候補消去。
                    (setq row (first coord) col (second coord))
                    (setq intersection-of-tuple-and-candidate
			  (sort (intersection tuple (aref brd row col) :test #'equal) #'<))
                    (if (< (length intersection-of-tuple-and-candidate)
			   (length (aref brd row col)))
			(setq check t)
			) ;; end if
                    (setq cannotbe-candidate (set-difference (aref brd row col) tuple :test #'equal))
                    (dolist (p cannotbe-candidate)
                      (setq color-brd (set-colored-candidate color-brd coord p '*elimination-color*))
                      )
                    (setf (aref brd row col) intersection-of-tuple-and-candidate)
                    )

                  (when check ;; plot用の情報表示。
                    (method-applied 'do-tuples-hidden)
                    (cond
                      ((= r 1)
                       (plot-info "単独候補" *difficulty-only-one* 8)
		       )
                      ((>= r 2)
                       (setf msg (format nil "~d国同盟(hidden型)" r))
                       (plot-info msg
                                  (* (expt 2 (- r 2)) *difficulty-tuples-hidden*)
                                  (+ 16 (width r))) )
		      ) ;; end cond
		    )	;; end when

                  (dolist (coord except) ;; hidden tuplesに対する処理。[tuple]に含まれる候補を消去。
		    (setq row (first coord))
		    (setq col (second coord))

		    (setf cand (aref brd row col))

		    (when (pure-listp cand)
		      (let (tmp)
			(setf tmp (set-difference cand tuple :test #'equal))
			(when (< (length tmp) (length cand))
			  (setf check t)
			  (cond
			    ((equal kind 'row)
			     (record-quiz-info :function-name 'do-n-tuples)
			     (record-quiz-info :explanation "hidden tuples")
			     (record-quiz-info :position (list 'row (first coord)))
			     (record-quiz-info :candidate
					       (list (list 'cannotbe (list row col) cannotbe-candidate)))
			     (push (record-quiz-info) quiz-info)
			     (reset-record-quiz-info)
			     )
			    ((equal kind 'col)
			     (record-quiz-info :function-name 'do-n-tuples)
			     (record-quiz-info :explanation "hidden tuples")
			     (record-quiz-info :position (list 'col (second coord)))
			     (record-quiz-info :candidate
					       (list (list 'cannotbe (list row col) cannotbe-candidate)))
			     (push (record-quiz-info) quiz-info)
			     (reset-record-quiz-info)
			     )
			    ((equal kind 'block)
			     (record-quiz-info :function-name 'do-n-tuples)
			     (record-quiz-info :explanation "hidden tuples")
			     (record-quiz-info :position (list 'block (block-num row col)))
			     (record-quiz-info :candidate
					       (list (list 'cannotbe (list row col) cannotbe-candidate)))
			     (push (record-quiz-info) quiz-info)
			     (reset-record-quiz-info)
			     )
			    )
			  ) ;; end when
			)   ;; end let
		      )	    ;; end when
		    )   ;; end dolist

                  (setf except nil)
                  (cond ;ブロック内のtupleが直線上に並ぶなら行/列からも候補を消去。
                    ((and (equal kind 'block) (same-row-only coordinates))
                     (setf except (row-except coordinates)))
                    ((and (equal kind 'block) (same-col-only coordinates))
                     (setf except (col-except coordinates))))
                  (when except
                    (dolist (coord except)
		      (let (row col)
			(setq row (first coord))
			(setq col (second coord))
			(setf cand (aref brd row col))
			(when (pure-listp cand)
                          (setf intersection-of-tuple-and-candidate (set-difference cand tuple :test #'equal))
                          (if (< (length intersection-of-tuple-and-candidate) (length cand))
			      (setf check t)
			      ) ;; end if
                          (setf intersection-of-tuple-and-candidate
				(sort (copy-seq intersection-of-tuple-and-candidate) #'<))
                          (dolist (p tuple)
                            (setf color-brd (set-colored-candidate color-brd coord p '*elimination-color*))
                            )
                          (setf (aref brd row col) intersection-of-tuple-and-candidate)

			  (record-quiz-info :function-name 'do-n-tuples)
			  (record-quiz-info :explanation "ブロック内のtupleが直線状に並んでいる")
			  (record-quiz-info :position (list 'cell (list row col)))
			  (record-quiz-info :candidate
					    (list (list 'mustbe (list row col) tuple)))
			  (push (record-quiz-info) quiz-info)
			  (reset-record-quiz-info)

			  ) ;; end when
			)   ;; end let
		      )	    ;; end dolist
		    )	  ;; end when

                  (when check ;; plot用の情報表示。
		    (method-applied 'do-tuples-naked)
		    (cond
		      ((= r 1)
		       (plot-info "単独候補" *difficulty-only-one* 8)
		       )
		      ((>= r 2)
		       (setf msg (format nil "~d国同盟(naked型)" r))
		       (plot-info msg
                                  (+ (* 2 (- r 2)) *difficulty-tuples-naked*)
                                  (+ 15 (width r))) )
		      ) ;; end cond
		    )	;; end when

		  (when check ;; for record-quiz-info
		    (dolist (cell coordinates)
                      (setf cand (aref board (first cell) (second cell)))
		      (cond
			((and (= r 1) (equal kind 'row)) ;; 行で唯一の候補。
			 (record-quiz-info :function-name 'do-n-tuples)
			 (record-quiz-info
			  :explanation (format nil "行で唯一の候補なので確定値。セル内の他の候補を削除可"))
			 (record-quiz-info :position (list 'or (list 'row i) (list 'cell cell)))
			 (record-quiz-info :candidate
					   (list (cannotbe-list
						  cell (set-difference cand tuple :test #'equal))))
			 (push (record-quiz-info) quiz-info)
			 (reset-record-quiz-info)
			 )
			((and (= r 1) (equal kind 'col)) ;; 列で唯一の候補。
			 (record-quiz-info :function-name 'do-n-tuples)
			 (record-quiz-info
			  :explanation (format nil "列で唯一の候補なので確定値。セル内の他の候補を削除可"))
			 (record-quiz-info :position (list 'or (list 'col i) (list 'cell cell)))
			 (record-quiz-info :candidate
					   (list (cannotbe-list
						  cell (set-difference cand tuple :test #'equal))))
			 (push (record-quiz-info) quiz-info)
			 (reset-record-quiz-info)
			 )
			((and (= r 1) (equal kind 'block)) ;; ブロックで唯一の候補。
			 (record-quiz-info :function-name 'do-n-tuples)
			 (record-quiz-info
			  :explanation (format nil "ブロックで唯一の候補なので確定値。セル内の他の候補を削除可"))
			 (record-quiz-info :position (list 'or (list 'block i) (list 'cell cell)))
			 (record-quiz-info :candidate
					   (list (cannotbe-list
						  cell (set-difference cand tuple :test #'equal))))
			 (push (record-quiz-info) quiz-info)
			 (reset-record-quiz-info)
			 )
			((>= r 2)
			 (cond
			   ((equal kind 'row)
			    (record-quiz-info :function-name 'do-n-tuples)
			    (record-quiz-info :explanation (format nil "行方向に~d国同盟が成立" r))
			    (record-quiz-info :position (list 'and (list 'row i) (list 'cell cell)))
			    (record-quiz-info :candidate (list (cannotbe-list cell tuple)))
			    (push (record-quiz-info) quiz-info)
			    (reset-record-quiz-info)
			    )
			   ((equal kind 'col)
			    (record-quiz-info :function-name 'do-n-tuples)
			    (record-quiz-info :explanation (format nil "列方向に~d国同盟が成立" r))
			    (record-quiz-info :position (list 'and (list 'col i) (list 'cell cell)))
			    (record-quiz-info :candidate (list (cannotbe-list cell tuple)))
			    (push (record-quiz-info) quiz-info)
			    (reset-record-quiz-info)
			    )
			   ((equal kind 'block)
			    (record-quiz-info :function-name 'do-n-tuples)
			    (record-quiz-info :explanation (format nil "ブロック内に~d国同盟が成立" r))
			    (record-quiz-info :position (list 'and (list 'block i) (list 'cell cell)))
			    (record-quiz-info :candidate (list (cannotbe-list cell tuple)))
			    (push (record-quiz-info) quiz-info)
			    (reset-record-quiz-info)
			    )
			   ) ;; end cond
			 )   ;; end ((>= r 2)
			)    ;; end cond
		      )      ;; end dolist
		    )	     ;; end when

                  (when (and check (>= (mod (explanation-level) 10) 1)) ;メッセージ表示。
		    ;;(print-depth)
		    (cond
		      ((equal kind 'row)
		       (setf msg "行") )
		      ((equal kind 'col)
		       (setf msg "列") )
		      ((equal kind 'block)
		       (setf msg "ブロック") )
		      (t (error "can't happen. stop at do-tuples-sub(4)."))
		      ) ;; end cond

		    (cond
		      ((and (= r 1) (equal kind 'row)) ;; 行で唯一の候補。
		       (format t "~a[~d]の" msg (1+ i))
		       (print-colored-string 'green (format nil "[~a]" (first tuple)))
		       (format t "=")
		       (print-colored-string 'green (format nil "[~a]" (short-color-name 'green)))
		       (format t "は行で唯一の候補なので確定値です。~%")
		       )
		      ((and (= r 1) (equal kind 'col)) ;; 列で唯一の候補。
		       (format t "~a[~d]の" msg (1+ i))
		       (print-colored-string 'green (format nil "[~a]" (first tuple)))
		       (format t "=")
		       (print-colored-string 'green (format nil "[~a]" (short-color-name 'green)))
		       (format t "は列で唯一の候補なので確定値です。~%")
		       )
		      ((and (= r 1) (equal kind 'block)) ;; ブロックで唯一の候補。
		       (format t "~a[~d]の" msg (1+ i))
		       (print-colored-string 'green (format nil "[~a]" (first tuple)))
		       (format t "=")
		       (print-colored-string 'green (format nil "[~a]" (short-color-name 'green)))
		       (format t "はブロックで唯一の候補なので確定値です。~%")
		       )
		      ((>= r 2)
		       (format t "~a[~d]の~s=" msg (1+ i) sorted-tuple)
		       (cond
                         ((show-color-board)
                          (print-colored-string 'green (format nil "[~a]" (short-color-name 'green))))
                         (t (format t "[~a]" *sharp-mark*)))
		       (format t "に対して~d国同盟が成立しています。~%" r)
		       )
		      ) ;; end cond

		    (when (show-color-board)
		      ;;(tabs (depth))
		      (format t "  ==> ")
		      (print-colored-string
		       '*elimination-color* (format nil "[~a]" (short-color-name '*elimination-color*)))
		      (format t "の位置から候補を削除できます。~%")
		      ) ;; end when

		    (when (print-check)
		      (setf chk-brd (make-null-check-board))
		      ;;(format t "coordinates = ~s~%" coordinates)
		      (dolist (cell coordinates) ;; [coordinates] ::= hidden tuplesのアドレス。
                        (setf (aref chk-brd (first cell) (second cell)) *sharp-mark*)
                        (setf cand (aref board (first cell) (second cell)))
			;; [tuple] ::= [r]組のセル内の候補の和集合から[r]個選ぶ組み合わせのひとつ。
                        (dolist (p tuple) ;; セル内の確定する候補を緑で彩色する。
                          (setf color-brd (set-colored-candidate color-brd cell p 'green))
			  ;;(record-quiz-info :candidate (list 'mustbe cell p))
			  )
                        ;; 候補が確定するセル内の確定候補以外の候補を赤で彩色する。
                        (dolist (p (set-difference cand tuple :test #'equal))
                          (setf color-brd (set-colored-candidate color-brd cell p '*elimination-color*))
			  )
                        ;; 確定候補のハウス内にある、確定候補と同じ値の候補を赤で彩色する。
                        (when (= (length tuple) 1)
                          (setf cells (set-difference (same-house-cells cell) (list cell) :test #'equal))
                          (dolist (p cells)
			    (setf cand (aref board (first p) (second p)))
			    (when (and (pure-listp cand) (member (first tuple) cand :test #'equal))
			      (setf color-brd
				    (set-colored-candidate color-brd p (first tuple) '*elimination-color*))
			      ) ;; end when
			    )	;; end dolist
                          )	;; end when
                        )	;; end dolist
		      (cond
                        ((show-color-board)
                         (print-normal color-brd))
                        (t (print-check-board chk-brd brd)))
		      ) ;; end when
		    (when (and check (>= (explanation-level) 10))
		      (print-board (collect-decided-in-board (new-board brd)))
		      ) ;; end when
		    )	;; end when
                  )	;; end let
                )	;; end dolist
	      )		;; end let
	    )		;; end dolist
          )		;; end let
        )		;; end do
      )			;; end (dotimes (i *board-size*))
    (return-from do-tuples-sub (values (clean-up-board brd) quiz-info))
    ) ;; end let
  ) ;; end do-tuples-sub

(defun row-except (coordinates)
"同じ行に存在する座標[coordinates]を含まない同一行内のすべての座標のリストを返す。
coordinates::=( ([R_1] [C_1])...([R_n] [C_n]) )"
  (if (not (same-row-only coordinates)) (error "row-except:同じ行に属さない座標を含んでいます。"))
  (row-except-without-error-check coordinates))

(defun row-except-without-error-check (coordinates)
  (let (row (result nil))
    (setf row (first (first coordinates)))
    (dotimes (j *board-size*)
      (if (not (member (list row j) coordinates :test #'equal)) (push (list row j) result)))
    (return-from row-except-without-error-check result)))

(defun col-except (coordinates)
"同じ列に存在する座標[coordinates]を含まない同一列内のすべての座標のリストを返す。
coordinates::=( ([R_1] [C_1])...([R_n] [C_n]) )"
  (if (not (same-col-only coordinates)) (error "col-except:同じ行に属さない座標を含んでいます。"))
  (col-except-without-error-check coordinates))

(defun col-except-without-error-check (coordinates)
  (let (col (result nil))
    (setf col (second (first coordinates)))
    (dotimes (i *board-size*)
      (if (not (member (list i col) coordinates :test #'equal)) (push (list i col) result)))
    (return-from col-except-without-error-check result)))

(defun block-except (coordinates)
"同じブロックに存在する座標[coordinates]を含まない同一ブロック内のすべての座標のリストを返す。
coordinates::=( ([R_1] [C_1])...([R_n] [C_n]) )"
  (if (not (same-block-only coordinates)) (error "col-except:同じ行に属さない座標を含んでいます。"))
  (block-except-without-error-check coordinates))

(defun block-except-without-error-check (coordinates)
  (let (blk-num row row-base col col-base (result nil))
    (setf blk-num (block-num (first (first coordinates)) (second (first coordinates))))
    ;;(setf blk-num (same-block-only coordinates))
    (setf row-base (block-base-row blk-num))
    (setf col-base (block-base-col blk-num))
    (dotimes (i *block-size*)
      (setf row (+ row-base i))
      (dotimes (j *block-size*)
        (setf col (+ col-base (mod j *block-size*)))
        ;;(format t "row = ~d, col = ~d~%" row col)
        (if (not (member (list row col) coordinates :test #'equal)) (push (list row col) result))))
    (return-from block-except-without-error-check result)))

(defun gathering-coordinates (brd n kind)
"[n]行・[n]列・ブロック[n]の未確定候補を持つセル・アドレスを集計する。"
  (let (row col coordinates)
    (setf coordinates nil)
    (dotimes (j *block-size*)
      (cond
        ((equal kind 'row)
         (setf row n)
         (setf col j))
        ((equal kind 'col)
         (setf row j)
         (setf col n))
        ((equal kind 'block)
         (setf row (+ (block-base-row n) (floor j *block-size*)))
         (setf col (+ (block-base-col n) (mod j *block-size*))))
        (t (error "can't happen. stop at gathering-candidates.")))
      (if (pure-listp (aref brd row col)) (push (list row col) coordinates)) )
    (return-from gathering-coordinates coordinates)))

(defun do-nice-loop (board)
"Nice Loopの実装

(1) b/b plotによりnice loopの経路候補となるグラフを生成する。
(2) 頂点をひとつ選び nice loop連鎖ルールを満たす経路を探す。
(3) もしあれば削除可能候補を削除する。"
  (let (brd graph nice-path-list connected-groups elm-list elm-brd dfc
            nice-loops total-elm-list fmt wd str quiz-info-list pos-info)

    (if (finished-p board) (return-from do-nice-loop board))

    (setf brd (new-board board))
    (setf nice-loops 0)
    (setf total-elm-list nil)
    (nice-depth nil)
    (nice-count 0)

    (setf elm-brd (new-board brd))
    (setf graph (do-bb-plot brd)) ;; b/b-plotによりグラフ[graph]を作成する。
    (setf connected-groups (get-connected-group graph)) ;; グラフ[graph]内の全ての連結成分のリストを得る。
    (dolist (connected-group connected-groups)
      ;;[nice-path-list]は重複が省かれ、連鎖が短い順に整列させたNice Loopのリスト。
      (setf nice-path-list (reduce-nice-path-list (find-nice-loop graph connected-group)))

      (debug-write "do-nice-loop" (format nil "nice-path-list=~a~%" nice-path-list))

      ;;Nice Loop成立時の盤面全体のリンク関係をGraphViz(http://www.graphviz.org)用のデータとして
      ;;出力する。ファイル名は既定では「LinkMap-xxx.gv」。これらのファイル群をGraphVizのコマンド
      ;;  > dot -Tpng LinkMap-xxx.gv -o LinkMap-xxx.png
      ;;で処理することでリンクマップが得られる。[xxx]部分は3桁の整数。
      (when (and (identity nice-path-list) (output-nice-graph))
        (output-nice-colors graph nice-path-list *edge-colors*)
        (force-output))

      (setf quiz-info-list nil)
      (dolist (nice-path nice-path-list)
        (setf elm-list (make-elimination-list brd nice-path))

	;; [guess-game]用の情報収集。
	(debug-write "do-nice-loop-2" (format nil "nice-path=~a~%" nice-path))
	(debug-write "do-nice-loop-2-5" (format nil "elm-list=~a~%" elm-list))

	(when (identity elm-list)
	  #|
	  (setq nice-pos-info (first elm-list)) ;; [elm-list]の先頭要素しか使っていない。複数要素はあり得る。
	  (setq pos-info
		(list
		 (first (second nice-pos-info))
		 (first nice-pos-info)
		 (second (second nice-pos-info))
		 )	      ;; end list
		)  ;; end setq
	  |#
	  (setq pos-info nil) ;; 2024-04-07
	  (dolist (p elm-list)
	    (push
	     (list
	      (first (second p))
	      (first p)
	      (second (second p))
	      )
	     pos-info)
	    ) ;; end dolist

	  (debug-write "do-nice-loop-2-6" (format nil "pos-info=~a~%" pos-info))
	  (record-quiz-info :function-name 'do-nice-loop)
	  (cond
	    ((equal (first nice-path) 'continuous)
	     (record-quiz-info :explanation *continuous-nice*)
	     )
	    ((equal (first nice-path) 'discontinuous)
	     (record-quiz-info :explanation *discontinuous-nice*)
	     )
	    ) ;; end cond
	  ;; (print-nice-board nice-path) でNice Loop経路情報盤面表示。
	  ;; (print-nice-notation nice-path) でNice Loop経路情報表示。
	  (record-quiz-info :position nice-path)
	  (record-quiz-info :candidate pos-info)
	  (push (record-quiz-info) quiz-info-list)

	  ;;(print-repeated-char-string 72 #\-)
	  ;;(format t "quiz-info-list=~s~%" quiz-info-list)
	  ;;(print-repeated-char-string 72 #\-)

	  (reset-record-quiz-info)
	  (debug-write "do-nice-loop-3" (format nil "quiz-info=~a~%" (first quiz-info-list)))
	  ) ;; end when

        (when (and
	       (identity elm-list)
	       (not (subsetp elm-list total-elm-list :test #'equal))
	       )
          (incf nice-loops)
          (setf total-elm-list (append elm-list total-elm-list))
          (setf dfc (+ *difficulty-nice-loop* (* (- (length nice-path) 2) 2)))
          ;;(plot-info "Nice Loop" dfc 9)
          (cond
            ((equal (first nice-path) 'continuous)
             (setf wd (width (* *board-size* *board-size*)))
             (setf fmt (format nil "Nice Loop(c\#~~~d\,'0\d)" wd))
             (setf str (format nil fmt (1- (length nice-path))))
             (plot-info str dfc (length str)))
            ((equal (first nice-path) 'discontinuous)
             (setf wd (width (* *board-size* *board-size*)))
             (setf fmt (format nil "Nice Loop(d\#~~~d\,'0\d)" wd))
             (setf str (format nil fmt (1- (length nice-path))))
             (plot-info str dfc (length str))))
          (method-applied 'do-nice-loop)
          (when (>= (mod (explanation-level) 10) 1)
            ;;(print-depth)
            (print-nice-notation nice-path)
            (format t "~%  ==> ")
            (print-elimination-list elm-list)
            (terpri)
            (if (print-check) (print-nice-board nice-path)))
          (if (and (integerp (max-nice-loops)) (>= nice-loops (max-nice-loops))) (return)))
	) ;; end dolist
      ) ;; end dolist

    (let (color-brd cells cell row col cand num kind)
      (setf color-brd (new-board board))
      (when (identity total-elm-list)
        (dolist (elm total-elm-list)
          ;; [elm] ::= ([セル・アドレス] ([削除種類] [削除可能候補])) ;
          ;; [削除種類] ::= cannotbe | mustbe ;
          ;; [削除可能候補] ::= [number] | ([number]...) ;
          (setf cell (first elm))
          (setf row (first cell) col (second cell))
          (setf cand (aref board row col))
          (setf kind (first (second elm)))
          (setf num (second (second elm)))
          (if (and (identity num) (atom num)) (setf num (list num)))
          (cond
            ((equal kind 'cannotbe)
             (dolist (p num)
               (setf color-brd (set-colored-candidate color-brd cell p '*elimination-color*))))
            ((equal kind 'mustbe)
             (setf num (first num))
             ;; 確定値となる候補を緑で彩色する。
             (setf color-brd (set-colored-candidate color-brd cell num 'green))
             ;; 確定値となる候補と同一セル内の他の候補数字を削除色(赤)で彩色する。
             (dolist (p (set-difference cand (list num) :test #'equal))
               (setf color-brd (set-colored-candidate color-brd cell p '*elimination-color*))
               )
             ;; 確定値となるセルのハウス内に存在する確定値と同じ値の候補数字を削除色(赤)で彩色する。
             (setf cells (set-difference (same-house-cells cell) (list cell) :test #'equal))
             (dolist (cell cells)
               (setf cand (aref brd (first cell) (second cell)))
               (when (and (pure-listp cand) (member num cand))
                 (setf color-brd (set-colored-candidate color-brd cell num '*elimination-color*))
                 )
               )
             )
            )
          (setf (aref elm-brd row col) *at-mark*)
	  ) ;; end dolist
        (when (print-check)
          ;;(print-depth)
          (format t "Nice Loopにより")
          (cond
            ((show-color-board)
             (print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*))))
            (t (format t "[~a]" *at-mark*)))
          (format t "の位置から候補を削除できます。~%")
          (cond
            ((show-color-board)
             (print-normal color-brd))
            (t (print-mini elm-brd)))
	  ) ;; end when
	(debug-write "do-nice-loop-4" (format nil "total-elm-list=~a~%" total-elm-list))
        (setf brd (do-elimination brd total-elm-list))
        (if (>= (explanation-level) 10) (print-board brd))
	) ;; end when
      ) ;; end inner let

    (return-from do-nice-loop (values (clean-up-board brd) (list (list quiz-info-list))))
    ) ;; end let
  ) ;; end do-nice-loop

(defun find-nice-loop (graph connected-group)
"Nice loopの経路を発見して返す。経路が存在しなければ[nil]を返す。
経路は「Nice loop notatione」を表すリストとして返す。
[経路] ::= ( {continuous|discontinuous} ([cell-0] [inf-type] [label] [cell-1])... ) | nil ;"
  (let (unseen-cell nice-path env (nice-path-list nil))

    (dolist (start-cell connected-group)
      ;;unseen情報を毎回復元して,最初の[unseen-cell]を設定。
      (setf graph (setup-graph-unseen graph))
      (setf unseen-cell (pop-unseen-cell graph start-cell))

      ;;[env]::=([start-cell] [parent] [last-info] [path] [nice-path] [nice-path-list]) ;
      (setf env (list start-cell nil nil nil nil nil))
      (setf nice-path (find-nice-loop-sub graph nil nil start-cell unseen-cell env))
      (if (identity nice-path) (setf nice-path-list (append nice-path-list nice-path))))

    (when (debug-write-p "find-nice-loop")
      (if (equal (first nice-path-list) 'continuous) (format t "~a~%" nice-path-list))
      ) ;; end when

    (return-from find-nice-loop nice-path-list)))

(defun find-nice-loop-sub (graph inf-0 label-0 cell-0 unseen-cell env)
"[inf-0],[label-0]という連鎖条件と[env]で指定される環境を持つセル[cell-0]から[unseen-cell]
を通る Nice Loopを探して返す。

[env] ::= ([start-cell] [parent] [last-info] [path] [nice-path] [nice-path-list]) ;"
  (let (start-cell parent last-info path nice-path nice-path-list
                   path-list nice-type-list tmp-nice-path tmp)

    (nice-count (1+ (nice-count)))
    (nice-depth (1+ (nice-depth)))

    (when (debug-write-p "find-nice-loop-sub")
      (format t "~4,'0d:~dn> (find-nice-loop-sub [graph] " (nice-count) (nice-depth))
      (format t "~s ~s ~s ~s [env])~%" inf-0 label-0 cell-0 unseen-cell))

    ;; 環境の設定。
    (setf start-cell (nth 0 env) parent (nth 1 env) last-info (nth 2 env))
    (setf path (nth 3 env) nice-path (nth 4 env) nice-path-list (nth 5 env))

    (when (debug-write-p "find-nice-loop-sub(1)" t)
      (format t "env=~s~%" env)
      (format t "start-cell=~s~%" start-cell)
      (format t "parent=~s~%" parent)
      (format t "last-info=~s~%" last-info)
      (format t "path=~s~%" path)
      (format t "nice-path=~s~%" nice-path)
      (format t "nice-path-list=~s~%" nice-path-list))

    (loop
       (nice-loop-count (1+ (nice-loop-count)))

       (when (null cell-0)
         (nice-depth (1- (nice-depth)))
         (setf nice-path nil)
         (return-from find-nice-loop-sub nice-path-list))

       (when (null path)
         ;;(setf path-list (nice-p (new-graph graph) inf-0 label-0 cell-0 unseen-cell))
         (setf path-list (nice-p graph inf-0 label-0 cell-0 unseen-cell))
         (dolist (lst (cdr path-list))
           (setf env (list start-cell parent last-info lst nice-path nice-path-list))
           (setf tmp (find-nice-loop-sub graph inf-0 label-0 cell-0 unseen-cell env))
           (setf nice-path-list (append nice-path-list tmp)) )
         (setf path (first path-list)) )
       (cond
         ((and
           (identity path)
           (equal start-cell unseen-cell)
           (valid-nice-length-p nice-path) ) ;Loop成立。
          (setf tmp-nice-path (cons path nice-path))
          (setf nice-type-list (nice-loop-p graph tmp-nice-path))
          (setf tmp-nice-path (reverse tmp-nice-path))
          (dolist (nice-type nice-type-list)
            (cond
              ((and
                (equal (first nice-type) 'continuous)
                (identity tmp-nice-path)) ;連続的 nice loop成立。
               (push (cons 'continuous tmp-nice-path) nice-path-list))
              ((and
                (equal (first nice-type) 'discontinuous)
                (identity tmp-nice-path)) ;不連続 nice loop成立。
               (push (cons 'discontinuous tmp-nice-path) nice-path-list))
              (t (do-nothing) ))))
         ((and
           (identity path)
           (not (cells-in-use-p unseen-cell tmp-nice-path))) ;連鎖成立。「先」を探索。
          (push path nice-path)
          (push cell-0 parent)
          (setf cell-0 unseen-cell)
          (push (list inf-0 label-0) last-info)
          (setf inf-0 (nth 1 path) label-0 (nth 2 path)))
         ((and
           (identity path)
           (cells-in-use-p unseen-cell tmp-nice-path)) ;閉路防止。
          (do-nothing))
         ((null path)                   ;連鎖不成立。
          (do-nothing)))

       (loop                    ;未訪問セル[unseen-cell]をひとつ返す。
          (setf unseen-cell (pop-unseen-cell graph cell-0))
          (if (identity unseen-cell) (return)) ;exit this loop.
          ;;現在のセル[cell-0]に未訪問セルがなければバックトラックして探す。
          (when (null parent)
            (nice-depth (1- (nice-depth)))
            (setf nice-path nil)
            (return-from find-nice-loop-sub nice-path-list))
          (pop nice-path)
          (setf tmp (pop last-info) inf-0 (first tmp) label-0 (second tmp))
          (setf cell-0 (pop parent))
          (if (null cell-0) (return)))
       (setf path nil) )
    (nice-depth (1- (nice-depth)))
    (return-from find-nice-loop-sub nice-path-list)  ))

(defun new-graph (graph)
"グラフ[graph]と同じ内容を持つ新しいグラフを作成して返す。"
  (let (gr)
    ;;(setf gr (make-array (list *board-size* *board-size*) :initial-element nil))
    (setf gr (make-graph))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (when (typep (aref graph i j) 'vertex)
          (setf (aref gr i j)
                (make-vertex
                 :bivalue-cell (vertex-bivalue-cell (aref graph i j))
                 :edge-color (vertex-edge-color (aref graph i j))
                 :parent (vertex-parent (aref graph i j))
                 :fringe-weight (vertex-fringe-weight (aref graph i j))
                 :status (vertex-status (aref graph i j))
                 :unseen (vertex-unseen (aref graph i j))
                 :adj-list (vertex-adj-list (aref graph i j)))))))
    (return-from new-graph gr)))

(defun make-graph ()
"新しいグラフ型データをひとつ作成して返す。"
  (let (gr)
    (setf gr (make-array (list *board-size* *board-size*) :initial-element nil))
    (return-from make-graph gr)))

(defun cells-in-use (nice-path)
"探索中の[nice-path]経路中で使用されているセルのリストを返す。
[nice-path]         ::= ( [cell-info]... ) ;
[cell-info]         ::= ( [cell-0] [inf-type] ([label]...) [cell-1]) ;"
  (let ((cells nil))
    (dolist (cell-info nice-path)
      (push (first cell-info) cells))
    (push (nth 3 (first (last nice-path))) cells)
    (return-from cells-in-use cells)))

(defun cells-in-use-p (cell nice-path)
"セル[cell]が探索中のNice Loop経路[nice-path]に含まれるセルかどうかを返す。"
  (member cell (cells-in-use nice-path) :test #'equal))

(defun valid-nice-length-p (nice-path)
"Nice Loopの探索長さが設定された範囲かどうかを返す。"
  (let (ok)
    (setf ok (and (integerp *min-nice-length*)
                  (or (integerp *max-nice-length*) (null *max-nice-length*))))
    (if (not ok) (return-from valid-nice-length-p nil))
    (cond
      ((null *max-nice-length*)
       (>= (1+ (length nice-path)) *min-nice-length*))
      (t (<= *min-nice-length* (1+ (length nice-path)) *max-nice-length*)))))

(defun nice-loop-p (graph nice-path)
"Nice Loopの成立条件を満たしているかどうかを要素とするリストを返す。
    ・連続的Nice Loopの条件を満たしている場合は ('continuous [cell-info]),
    ・不連続Nice Loopの条件を満たしている場合は ('discontinuous [cell-info]),
    ・上記いずれの条件も満たさない場合は[nil]。
    ・[cell-info]はループ開始セルの成立条件。

不連続Nice Loopでのループ開始セルに対する連鎖ルール例外適用条件は次の3つ。
    Type 1: ループ開始セルが2つのweak linkを持ち、それらのラベルが同じ。
    Type 2: ループ開始セルが2つのstrong linkを持ち、それらのラベルが同じ。
    Type 3: ループ開始セルがstrong linkとweak linkを持ち、それらのラベルが異なる。

[nice-path]         ::= ( [cell-info]... ) ;
[cell-info]         ::= ( [start-cell] [inf-type] ([label]...) [last-cell]) ;
[cont-nice]         ::= ('continuous [cell-info]) ;
[discont-nice]      ::= ('discontinuous [cell-info]) ;

返り値 ::= ( {[cont-nice] | [discont-nice]}... ) | [nil] ;"
  (let (start-node start-cell start-inf start-labels aim-label 2nd-cell unseen-cell
                   last-node last-cell last-inf last-labels result result-list)

    (when (debug-write-p "nice-loop-p")
      (format t "(nice-loop-p [graph] ")
      ;;(print-inf-chain nice-path)
      (format t "~s)~%" nice-path) )
    
    (if (null nice-path) (return-from nice-loop-p nil))

    (setf start-node (nth 0 (last nice-path)) start-cell (nth 0 start-node))
    (setf start-inf  (nth 1 start-node)       start-labels (nth 2 start-node))
    (setf last-node  (nth 0 nice-path)        last-cell (nth 0 last-node))
    (setf last-inf   (nth 1 last-node)        last-labels (nth 2 last-node))
    (setf 2nd-cell   (nth 3 start-node)       unseen-cell (nth 3 last-node))
    
    (when (debug-write-p "nice-loop-p(2)")
      (format t "start-node=~s~%" start-node)
      (format t "(start-inf start-labels start-cell)=(~s ~s ~s)" start-inf start-labels start-cell)
      (format t "~%last-node=~s~%" last-node)
      (format t "(last-inf last-labels last-cell)=(~s ~s ~s)~%" last-inf last-labels last-cell)
      (force-output))

    (if (not (equal start-cell unseen-cell)) (return-from nice-loop-p nil))

    (if (not (and (typep (aref graph (first start-cell) (second start-cell)) 'vertex)
                  (typep (aref graph (first last-cell) (second last-cell)) 'vertex)))
        (return-from nice-loop-p nil))

    ;; (last-inf last-labels last-cell) --> (start-inf start-labels start-cell)
    ;; が連続的 Nice Loop, あるいは不連続 Nice Loopの定義を満たしているかを調べる。
    (setf result-list nil)

    ;; 連鎖ルールを満たしているなら連続的Nice Loop。
    (setf result (nice-p graph last-inf last-labels start-cell 2nd-cell))
    (dolist (i result)
      (if (intersection start-labels (nth 2 i))
       (push (list 'continuous i) result-list)))

    ;; ループ開始セルが2つのweak linkを持ち、それらのラベルが同じなら不連続Nice Loop。
    (when (and (equal start-inf 'weak)
               (equal last-inf 'weak)
               (setf aim-label (intersection (weak-label start-labels) (weak-label last-labels))))
      (setf aim-label (weak-label aim-label))
      (setf result (list 'discontinuous (list start-cell start-inf aim-label 2nd-cell)))
      (push result result-list))

    ;; ループ開始セルがweak linkとstrong linkを持ち、それらのラベルが異なるなら不連続Nice Loop。
    (when (and (equal start-inf 'weak)
               (equal last-inf 'strong)
               (setf aim-label (set-difference (abs-label start-labels) (abs-label last-labels))))
      (setf aim-label (weak-label aim-label))
      (setf result (list 'discontinuous (list start-cell start-inf aim-label 2nd-cell)))
      (push result result-list))

    ;; ループ開始セルが2つのstrong linkを持ち、それらのラベルが同じなら不連続Nice Loop。
    (when (and (equal start-inf 'strong)
               (equal last-inf 'strong)
               (setf aim-label (intersection (abs-label start-labels) (abs-label last-labels))))
      (setf aim-label (strong-label aim-label))
      (setf result (list 'discontinuous (list start-cell start-inf aim-label 2nd-cell)))
      (push  result result-list))

    ;; ループ開始セルがstrong linkとweak linkを持ち、それらのラベルが異なるなら不連続Nice Loop。
    (when (and (equal start-inf 'strong)
               (equal last-inf 'weak)
               (setf aim-label (set-difference (abs-label start-labels) (abs-label last-labels))))
      (setf aim-label (strong-label aim-label))
      (setf result (list 'discontinuous (list start-cell start-inf aim-label 2nd-cell)))
      (push result result-list))

    (when (debug-write-p "nice-loop-p")
      (format t "nice-loop-p returns ~s~%" result-list))

    (return-from nice-loop-p result-list)))

(defun nice-notation (nice-path)
  "find-nice-loopの返り値を Nice Loop表記法に変換する。

(\"連続的Nice Loop \" \"=\" \"[R1C1]\" \"=\" \"3\" \"=\" \"[R7C1]\" \"-\" \"3\" \"-\"
    \"[R8C3]\" \"=\" \"3\" \"=\" \"[R1C3]\" \"=\" \"9\" \"=\" \"[R1C1]\" \"=\")

[nice-path]         ::= ( [cell-info]... ) ;
[cell-info]         ::= ( [start-cell] [inf-type] ([label]...) [last-cell]) ;
[cont-nice]         ::= ('continuous [cell-info]) ;
[discont-nice]      ::= ('discontinuous [cell-info]) ;

返されるリスト内の要素(文字列)を順に表示すればよい。

例: (dolist (s (nice-notation nice-path)) (format t \"~a\" s))"
  (let (continuous-str discontinuous-str)
    (setq continuous-str (concatenate 'string *continuous-nice* *space*))
    (setq discontinuous-str (concatenate 'string *discontinuous-nice* *space*))

    (when (debug-write-p "nice-notation")
      (format t "nice-notation:nice-path=~s~%" nice-path)
      ) ;; end when

    (cond
      ((null nice-path) nil)
      ((equal (first nice-path) 'continuous)
       (cons continuous-str (continuous-notation (rest nice-path))))
      ((equal (first nice-path) 'discontinuous)
       (cons discontinuous-str (discontinuous-notation (rest nice-path))))
      (t (error "can't happen at nice-notation."))
      ) ;; end cond
    )	;; end let
  ) ;; end nice-notation

(defun internal-nice-notation (nice-notation)
  "ラベルあり／ラベルなしのnice notationで記述されたNice Pathを内部記法のNice Path記法に変換する。

(\"不連続Nice Loop\" \"[(A)r5c7]\" \"-2-\" \"[(B)r4c8]\" \"-3-\" \"[(C)r5c8]\" \"-2-\" \"[(A)r5c7]\") ==>
  (discontinuous ((4 6) weak (-2) (3 7)) ((3 7) weak (-3) (4 7)) ((4 7) weak (-2) (4 6)))

(\"不連続Nice Loop\" \"[r5c7]\" \"-2-\" \"[r4c8]\" \"-3-\" \"[r5c8]\" \"-2-\" \"[r5c7]\") ==>
  (discontinuous ((4 6) weak (-2) (3 7)) ((3 7) weak (-3) (4 7)) ((4 7) weak (-2) (4 6)))

(\"連続的Nice Loop\" \"=\" \"[(A)r8c5]\" \"-3-\" \"[(B)r4c5]\" \"-2-\" \"[(C)r6c6]\" \"=2=\" \"[(D)r7c6]\"
\"=5=\" \"[(E)r8c6]\" \"=3=\" \"[(A)r8c5]\" \"-\" ==>
(continuous ((7 4) weak (-3) (3 4)) ((3 4) weak (-2) (5 5)) ((5 5) strong (2) (6 5))
   ((6 5) strong (5) (7 5)) ((7 5) strong (3) (7 4)))
"
  (let (result)
    (cond
      ((string= (first nice-notation) *continuous-nice*)
       ;; 連続的Nice Loopの場合は「本体」の前後にlink種別記号が付随している。変換には関与しないので削除。
       (setq nice-notation (reverse (cdr (reverse nice-notation)))) ;; 末尾のlink種別記号を削除。
       (setq result (cons 'continuous (parse-nice-notation (pack-to-string (cddr nice-notation)))))
       )
      ((string= (first nice-notation) *discontinuous-nice*)
       (setq result (cons 'discontinuous (parse-nice-notation (pack-to-string (cdr nice-notation)))))
       )
      (t nil)
      ) ;; end cond
    (return-from internal-nice-notation result)
    ) ;; end let
  ) ;; end internal-nice-notation

(defun parse-nice-notation (nice-notation-body)
  "((4 6) weak (-2) (3 7) weak (-3) (4 7) weak (-2) (4 6))
     ==> (((4 6) weak (-2) (3 7)) ((3 7) weak (-3) (4 7)) ((4 7) weak (-2) (4 6)))"
  (let (inter-notation result)
    (setq result nil)
    (setq inter-notation (parse-nice-notation-sub nice-notation-body))
    (loop
      (if (< (length inter-notation) 3) (return))
      (push (list
	     (first inter-notation)
	     (second inter-notation)
	     (third inter-notation)
	     (fourth inter-notation)
	     )
	    result)
      (setq inter-notation (nthcdr 3 inter-notation))
      ) ;; end loop
    (return-from parse-nice-notation (reverse result))
    ) ;; end let
  )

(defun pack-to-string (list-of-string)
  (let (tmp)
    (setq tmp "")
    (dolist (s list-of-string)
      (setq tmp (concatenate 'string tmp s))
      )
    (return-from pack-to-string tmp)
    ) ;; end let
  )

(defun parse-nice-notation-sub (nice-notation-body)
  "人間向けの記法で書かれたnice notationの本体部分を内部形式のnice notationに変換して返す。
[nice-notation-body] ::= \"[(A)r5c7]-2-[(B)r4c8]-3-[(C)r5c8]-2-[(A)r5c7]\"
(parse-nice-notation-sub \"[(A)r5c7]-2-[(B)r4c8]-3-[(C)r5c8]-2-[(A)r5c7]\")
  ==> ((4 6) weak (-2) (3 7) weak (-3) (4 7) weak (-2) (4 6))
"
  (let (result eos ch row col lbl-num lbl-kind)
    (setq result nil)
    (setq eos (cons nil nil))
    (with-input-from-string (stream nice-notation-body)
      (loop
	(setq ch (read-char stream nil eos))
	(if (eq ch eos)
	    (return-from parse-nice-notation-sub (reverse result))
	    ) ;; end if

	(when (char= ch #\[)
	  ;; [cell-clause] ::= "[" [ "(" [Label-char] ")" ] {"r"[n]"c"[m] | "R"[n]"C"[m]} "]" ;
	  (setq ch (read-char stream nil eos))

	  (when (char= ch #\() ;; \"(\"と\")\"に囲まれた[ラベル文字]を読み飛ばす。
	    (loop ;; [ラベル文字]が複数の英文字になった場合に備えて\"\)\"まで読み飛ばす(現在は必ず1文字)。
		  (if (char= (read-char stream nil eos) #\)) (return)) ;; exit loop.
		  )
	    ) ;; end when

	  (setq ch (read-char stream nil eos))
	  (when (member ch '(#\r #\R) :test #'char=) ;; "r[n]c[m]"
	    (setq row 0)
	    (loop ;; 9x9のナンプレでは[n]は1..9だが、16x16のビッグナンプレでは1..16の最大2桁。
		  (setq ch (read-char stream nil eos)) ;; read [row].
		  (if (not (digit-char-p ch)) (return)) ;; exit loop
		  (setq row (+ (* row 10) (digit-char-to-integer ch)))
		  ) ;; end loop
	    (debug-write "parse-nice-notation-1" (format nil "row=~d~%" row))

	    (if (not (member ch '(#\c #\C) :test #'char=))
		(return-from parse-nice-notation-sub nil)
		)
	    (setq col 0)
	    (loop ;; 9x9のナンプレでは[n]は1..9だが、16x16のビッグナンプレでは1..16の最大2桁。
		  (setq ch (read-char stream nil eos)) ;; read [col].
		  (if (not (digit-char-p ch)) (return)) ;; exit loop
		  (setq col (+ (* col 10) (digit-char-to-integer ch)))
		  ) ;; end loop
	    (debug-write "parse-nice-notation-2" (format nil "col=~d~%" col))
	    (push (list (1- row) (1- col)) result)
	    (debug-write "parse-nice-notation-2.1" (format nil "result=~a~%" result))
	    (debug-write "parse-nice-notation-2.4" (format nil "ch=~a~%" ch))
	    ) ;; end when
	  )   ;; end when

	(debug-write "parse-nice-notation-2.5" (format nil "ch=~a~%" ch))
	(when (member ch '(#\- #\=) :test #'char=) ;; weak linkとstrong link部の処理。
	  (if (char= ch #\=)
	      (setq lbl-kind 'strong)
	      (setq lbl-kind 'weak)
	      ) ;; end if
	  (setq lbl-num 0)
	  (loop
	    (setq ch (read-char stream nil eos))
	    (debug-write "parse-nice-notation-2.6" (format nil "ch=~a~%" ch))
	    (if (not (digit-char-p ch)) (return)) ;; exit loop
	    (setq lbl-num (+ (* lbl-num 10) (digit-char-to-integer ch)))
	    ) ;; end loop
	  (debug-write "parse-nice-notation-3" (format nil "lbl-num=~d~%" lbl-num))
	  (debug-write "parse-nice-notation-3.1" (format nil "ch=~a~%" ch))
	  (if (not ;; [label]の後に対応する"-"または"="が存在するかのチェック。
	       (or
		(and (equal lbl-kind 'strong) (char= ch #\=))
		(and (equal lbl-kind 'weak) (char= ch #\-))
		)
	       )
	      (return-from parse-nice-notation-sub nil)
	      ) ;; end if
	  (cond
	    ((equal lbl-kind 'strong)
	     (push 'strong result)
	     (push (list lbl-num) result)
	     )
	    ((equal lbl-kind 'weak)
	     (push 'weak result)
	     (push (list (- lbl-num)) result)
	     )
	    ) ;; end cond
	  (debug-write "parse-nice-notation-4" (format nil "lbl-num=~d~%" lbl-num))
	  ) ;; end when
	)   ;; end loop
      )     ;; with-input-from-string
    )	    ;; end let
  ) ;; end parse-nice-notation

(defun string-to-character-list (str)
  "引数の文字列[str]を文字のリストに変換して返す。
(string-to-character-list \"abc\") ==> (#\\a #\\b #\\c)"
  (let (result)
    (setq result nil)
    (dotimes (i (length str))
      (push (char str i) result)
      ) ;; end dotimes
    (return-from string-to-character-list (reverse result))
    ) ;; end let
  ) ;; end string-to-character-list

(defun print-nice-notation (nice-path)
  (letter-label-counter 0)
  (dolist (s (nice-notation nice-path))
    (format t "~a" s)))

(defun discontinuous-notation (discont-path)
  (let (label (lst nil))
    (dolist (node discont-path)
      (push (format nil "[~a~a]" (letter-labels) (cell-addr (nth 0 node))) lst)
      (setf label (nth 2 node))
      (cond
        ((equal (nth 1 node) 'strong)
         (cond
           ((> (length label) 1)
            (push (format nil "=~s=" (abs-label label)) lst))
           (t (push (format nil "=~d=" (abs (first label))) lst))))
        ((equal (nth 1 node) 'weak)
         (cond
           ((> (length label) 1)
            (push (format nil "-~s-" (abs-label label)) lst))
           (t (push (format nil "-~d-" (abs (first label))) lst))))
        (t (error "can't happen at discontinuous-notation."))))
    (push (format nil "[~a~a]" (letter-labels 0) (cell-addr (nth 3 (first (last discont-path)))))
          lst)
    (return-from discontinuous-notation (reverse lst))))

(defun continuous-notation (cont-path)
  (let (p (lst nil))
    (setf p (nth 1 (first (last cont-path))))
    (cond
      ((equal p 'strong)
       (push "=" lst))
      ((equal p 'weak)
       (push "-" lst))
      (t (error "can't happen at continuous-notation(1).")))
    (dolist (node cont-path)
      (push (format nil "[~a~a]" (letter-labels) (cell-addr (nth 0 node))) lst)
      (cond
        ((equal (nth 1 node) 'strong)
         (cond
           ((> (length (nth 2 node)) 1)
            (push (format nil "=~s=" (abs-label (nth 2 node))) lst))
           (t (push (format nil "=~d=" (abs (first (nth 2 node)))) lst))))
        ((equal (nth 1 node) 'weak)
         (cond
           ((> (length (nth 2 node)) 1)
            (push (format nil "-~s-" (abs-label (nth 2 node))) lst))
           (t (push (format nil "-~d-" (abs (first (nth 2 node)))) lst))))
        (t (error "can't happen at continuous-notation(2)."))))
    (push (format nil "[~a~a]" (letter-labels 0) (cell-addr (nth 3 (first (last cont-path))))) lst)
    (setf p (nth 1 (first cont-path)))
    (cond
      ((equal p 'strong)
       (push "=" lst))
      ((equal p 'weak)
       (push "-" lst))
      (t (error "can't happen at continuous-notation(3).")))
    (return-from continuous-notation (reverse lst)))) 

(defun print-inf-chain (inf-chain)
"Inference chainをnice loop表記法で表示する。
([cell-1] inf-type labels [cell-2]) ;"
  (let ((lst nil))
    (dolist (node inf-chain)
      (push (format nil "[~a]" (cell-addr (nth 0 node))) lst)
      (cond
        ((equal (nth 1 node) 'strong)
         (cond
           ((> (length (nth 2 node)) 1)
            (push (format nil "=~s=" (abs-label (nth 2 node))) lst))
           (t (push (format nil "=~d=" (abs (first (nth 2 node)))) lst))))
        ((equal (nth 1 node) 'weak)
         (cond
           ((> (length (nth 2 node)) 1)
            (push (format nil "-~s-" (abs-label (nth 2 node))) lst))
           (t (push (format nil "-~d-" (abs (first (nth 2 node)))) lst))))
        (t (error "can't happen at discontinuous-notation."))))
    (dolist (p (reverse lst)) (format t "~a" p))
    (return-from print-inf-chain t)))

(defun make-elimination-list (brd nice-path)
  "Nice loopの経路リスト[nice-path]から削除数字とセル・アドレスをセットにしたリストを返す。

[nice-path] ::= ( {continuous|discontinuous} [path]... ) | nil ;
[path] ::= ([cell-0] [inf-type] [label] [cell-1])
[返り値] ::= ([削除可能データ]...) | nil ;
[削除可能データ] ::= ([セル・アドレス] ([削除種類] [削除可能候補])) ;
[削除種類] ::= cannotbe | mustbe ;

例) (((1 1) (cannotbe 5)) ((5 8) (cannotbe 9)) ((8 8) (mustbe 4))) ==> r2c2<>5, r6c9<>9, r9c9=4"
  (let (result)
    (setf result
	  (cond
	    ((null nice-path) nil)
	    ((equal (first nice-path) 'continuous)
	     (make-cont-elm brd (cdr nice-path)))
	    ((equal (first nice-path) 'discontinuous)
	     (make-discont-elm brd (cdr nice-path)))
	    (t (error "can't happen at make-elimination-list."))
	    ) ;; end cond
	  ) ;; end setf
    (debug-write "make-elimination-list" (format nil "elimination-list=~a~%" result))
    (return-from make-elimination-list result)
    ) ;; end let
  ) ;; end make-elimination-list

(defun printable-elimination-list (elm-list)
"削除可能データのリストを表示形式のリストに変換する。

[削除可能データ] ::=   ([セル・アドレス] ([削除種類] [削除可能候補]))
                    | ([セル・アドレス] ([削除種類] ([削除可能候補]...))) ;
[削除種類] ::= cannotbe | mustbe ;
[表示形式リスト] ::= ([セル・アドレス] \"=\" [削除可能候補]) |
                     ([セル・アドレス] \"<>\" [削除可能候補])"
  (let ((result nil) p)
    (if (null elm-list) (return-from printable-elimination-list nil))
    (dolist (elm elm-list)
      ;; [elm] ::=   ([セル・アドレス] ([削除種類] [削除可能候補]))
      ;;           | ([セル・アドレス] ([削除種類] ([削除可能候補]...))) ;
      (cond
        ((atom (elm-cand elm))
         (setf p (list (elm-cand elm))))
        ((pure-listp (elm-cand elm))
         (setf p (elm-cand elm)))
        (t (error "can't happen at printable-elimination-list.")))
      (dolist (q p)
        (cond
          ((equal (elm-kind elm) 'cannotbe)
           (push (list (cell-addr (first elm)) *not-equal-mark* q) result))
          ((equal (elm-kind elm) 'mustbe)
           (push (list (cell-addr (first elm)) *equal-mark* q) result))
          (t (error "can't happen at print-elimination-list.")))))
    (return-from printable-elimination-list result)))

(defun print-elimination-list (elm-list)
"[printable-elimination-list]が返すリストを標準出力に出力する。"
  (let (p-list-list)
    (if (null elm-list) (return-from print-elimination-list nil))
    (setf p-list-list (printable-elimination-list elm-list))
    (dolist (p-list (list (first p-list-list)))
      (dolist (p-data p-list) (format t "~a" p-data)))
    (dolist (p-list (rest p-list-list))
      (format t ", ")
      (dolist (p-data p-list) (format t "~a" p-data)))
    (return-from print-elimination-list t)))

(defun elm-kind (elm)
"elm = ([セル・アドレス] ([削除種類] [削除可能候補])) ;"
  (first (second elm)))

(defun elm-cand (elm)
"[elm] ::= ([セル・アドレス]([削除種類] ([削除可能候補]...))) ; "
  (second (second elm)))

(defun make-cont-elm (brd path-list)
"連続的 nice loopの経路情報から実際に削除可能な候補とセル・アドレスをペアにしたリストを返す。

[返り値] ::= ([削除可能データ]...) | nil ;
[削除可能データ] ::= ([セル・アドレス] ([削除種類] [削除可能候補])) ;
[削除種類] ::= cannotbe | mustbe ;

定理１：
連続的nice loop内の２つのリンクが共にstrong inferenceであるセルXに対し、
それらのリンクのラベルがAとB(A≠B)であるならば、セルXにはAとB以外の数字候補は存在できない。

定理２：
連続的nice loop内の２つのセル間のリンクがweak inferenceであるならば、
そのリンクのラベルと同じ値の候補数字は、その２つのセルのどちらかに存在しなければならない。
したがって、リンク・ラベルの表す候補数字を２つのセルが属すユニットから削除できる。

[path-list] サンプル。(continuous ...)のcdr部分。

(
 ((5 0) weak (-8) (8 0))
 ((8 0) weak (-2) (7 0))
 ((7 0) strong (2) (7 5))
 ((7 5) strong (6) (3 5))
 ((3 5) strong (1) (5 5))
 ((5 5) weak (-1) (5 0))
) ;

連続的Nice Loopなので連鎖はループしている。
"
  (let (last-path last-inf last-label elm-list)

    (setf last-path   (car (last path-list))) ;; 上のサンプルなら ((5 5) weak (-1) (5 0)) 
    (setf last-inf    (nth 1 last-path))      ;; weak
    (setf last-label  (nth 2 last-path))      ;; (-1) i.e. Label "1" for weak link.
    (setf elm-list nil)

    ;; Theorem 1.
    (let (prev-inf prev-label next-inf next-label cell candidates tmp)
      (setf prev-inf last-inf prev-label last-label) ;; 先頭から処理するが、先頭の要素の「前」は最後の要素。
      (dolist (node path-list)
        (setf cell (nth 0 node)) ;; (nth 0 ((5 0) weak (-8) (8 0))) ==> (5 0)
        (setf candidates (aref brd (first cell) (second cell))) ;; セル(5 0)の要素。
        (setf next-inf (nth 1 node) next-label (nth 2 node)) ;; (nth 1 node) == weak, (nth 2 node) == (-1)
        (setf tmp (union (copy-seq prev-label) (copy-seq next-label)))
        (when (and (equal prev-inf 'strong)
                   (equal next-inf 'strong)
                   (not (equal prev-label next-label))
                   (not (set-equal tmp candidates)) )
	  ;; ([mustbe] ([数値]))または (([cannotbe] [差分_1])...([cannotbe] [差分_n]))
          (dolist (expr (cell-mustbe brd cell tmp))
            (push (list cell expr) elm-list)
	    ) ;; end dolist
	  )   ;; end when
        (setf prev-inf next-inf prev-label next-label)
	) ;; end dolist
      ) ;; end let

    ;; Theorem 2.
    (let (prev-cell next-cell inter-inf inter-label candidates cell-list)
      (setq cell-list nil)
      (dolist (node path-list)
        (setf prev-cell (nth 0 node) next-cell (nth 3 node))
        (setf inter-inf (nth 1 node) inter-label (nth 2 node))
        (when (equal inter-inf 'weak)
          (when (same-row-p prev-cell next-cell)
            (setf cell-list (union (same-row-cells prev-cell) cell-list)))
          (when (same-col-p prev-cell next-cell)
            (setf cell-list (union (same-col-cells prev-cell) cell-list)))
          (when (same-block-p prev-cell next-cell)
            (setf cell-list (union (same-block-cells prev-cell) cell-list)))
          ;;[prev-cell]と[next-cell]はリンク関係にあるので必ず同じユニットに属している。
          ;;したがって、必ず上記の少なくともひとつの条件を満たしている(全ての条件を満たしている場合もある)。
          (setf cell-list (remove prev-cell cell-list :test #'equal))
          (setf cell-list (remove next-cell cell-list :test #'equal))
          (dolist (cell cell-list)
            (setf candidates (aref brd (first cell) (second cell)))
            (when (and (pure-listp candidates) (member inter-label candidates :test #'equal))
              (push (list cell (list 'cannotbe inter-label)) elm-list))))))

    (return-from make-cont-elm elm-list)))

(defun make-discont-elm (brd path-list)
"不連続 nice loopの経路情報から実際に削除可能な候補とセル・アドレスをペアにしたリストを返す。

[返り値] ::= ([削除可能データ]...) | nil ;
[削除可能データ] ::= ([セル・アドレス] ([削除種類] [削除可能候補])) ;
[削除種類] ::= cannotbe | mustbe ;

定理３：
不連続nice loop内の不連続点であるセルXに対する２つのリンクが共にstrong inferenceであり
ラベルが共にAであるならば、セルXの値はAである。

定理４：
不連続nice loop内の不連続点であるセルXに対する２つのリンクが共にweak inferenceであり
ラベルが共にAであるならば、セルXから数字候補Aを削除できる。

定理５：
不連続nice loop内の不連続点であるセルXに対する２つのリンクがstrong inferenceと
weak inferenceであり、weak inferenceのラベルがAであるならば、セルXから数字候補Aを削除できる。"
  (let (start-path start-cell start-inf start-label
                   last-path last-inf last-label candidates (result nil))

    (setf start-path  (nth 0 path-list) start-cell  (nth 0 start-path))
    (setf start-inf   (nth 1 start-path) start-label (nth 2 start-path))
    (setf last-path   (car (last path-list)))
    (setf last-inf    (nth 1 last-path) last-label  (nth 2 last-path))

    (setf candidates (aref brd (first start-cell) (second start-cell)))

    (when (debug-write-p "make-discont-elm")
      (format t "~%path-list=~s~%" path-list)
      (format t "candidates=~s~%" candidates)
      (format t "start-path=~s~%" start-path)
      (format t "(start-cell start-inf start-label)=(~s ~s ~s)~%" start-cell start-inf start-label)
      (format t "last-path=~s~%" last-path)
      (format t "(last-inf last-label)=(~s ~s)~%" last-inf last-label))

    (cond
      ((and                             ;Theorem 3.
        (equal start-inf 'strong)
        (equal last-inf 'strong)
        (equal start-label last-label)
        (and (pure-listp candidates) (intersection (abs-label start-label) candidates))
        (not (set-equal (abs-label start-label) candidates)))
       (dolist (expr (cell-mustbe brd start-cell (union last-label start-label)))
         (push (list (abs-label start-cell) expr) result)))
       ;;(push (list start-cell (list 'mustbe (abs-label start-label))) result))
      ((and                             ;Theorem 4.
        (equal start-inf 'weak)
        (equal last-inf 'weak)
        (equal start-label last-label)
        (and (pure-listp candidates) (intersection (abs-label start-label) candidates)))
       (push (list start-cell (list 'cannotbe (abs-label start-label))) result))
      ((and                             ;Theorem 5.
        (equal start-inf 'strong)
        (equal last-inf 'weak)
        (and (pure-listp candidates) (intersection (abs-label last-label) candidates)))
       (push (list start-cell (list 'cannotbe (abs-label last-label))) result))
      ((and                             ;Theorem 5.
        (equal start-inf 'weak)
        (equal last-inf 'strong)
        (and (pure-listp candidates) (intersection (abs-label start-label) candidates)))
       (push (list start-cell (list 'cannotbe (abs-label start-label))) result))
      (t nil))
    (return-from make-discont-elm result)))

(defun do-elimination (brd elm-list)
  "削除可能候補リスト[elm-list]で指定された候補をボード[brd]から削除する。
[削除可能候補リスト] ::= ([削除可能データ]...) | nil ;
[削除可能データ] ::= ([セル・アドレス] ([削除種類] [削除可能候補])) ;
[削除種類] ::= cannotbe | mustbe ;
((8 3) (cannotbe 7)) means 7 can not be a candidate in r9c4."
  (let (cell row col tmp)
    (dolist (elm elm-list) ;; elm = [削除可能データ]
      (setf cell (first elm))
      (setf row (first cell) col (second cell))
      (cond
        ((equal (elm-kind elm) 'mustbe)
	 (setq tmp (elm-cand elm))
	 (cond
	   ((pure-listp tmp)
	    (setf (aref brd row col) (first tmp))
	    )
	   ((integerp tmp)
	    (setf (aref brd row col) tmp)
	    )
	   ) ;; end cond
	 )
        ((equal (elm-kind elm) 'cannotbe)
         (setf brd (do-trim-cell (elm-cand elm) brd row col)))
        (t (error "can't happen at do-elimination."))))
    (return-from do-elimination brd)
    ) ;; end let
  ) ;; end do-elimination

(defun print-nice-board (nice-path)
"Nice Loopの経路情報[nice-path]と消去できる候補位置[elm-list]を示す盤面を表示する。

[nice-path] ::= ( {continuous|discontinuous} [path]... ) | nil ;
[path]      ::= ([cell-0] [inf-type] [label] [cell-1])
[elm-list]  ::= ([elm]...) | nil ;
[elm]       ::= ([セル・アドレス] ([削除種類] [削除可能候補])) ;
[削除種類]  ::= cannotbe | mustbe ;"
  (let (chk-brd cell row col)
    (setf chk-brd (make-null-check-board))
    (letter-label-counter 0)
    (dolist (path (cdr nice-path))
      (setf cell (first path) row (first cell) col (second cell))
      ;;(letter-labels) ==> "(A)"..."(z)" 
      (cond
	((null (print-with-symbol-letter))
	 (print-with-symbol-letter t)
	 (setf (aref chk-brd row col) (subseq (letter-labels) 1 2))
	 (print-with-symbol-letter nil)
	 )
	((identity (print-with-symbol-letter))
	 (setf (aref chk-brd row col) (subseq (letter-labels) 1 2))
	 )
	) ;; end cond
      )	  ;; end dolist
    (print-mini chk-brd)
    (return-from print-nice-board t)))

(defun cell-mustbe (brd cell candidates)
"指定されたセル[cell]の内容が指定された候補[candidates]によって確定するならば
    ([mustbe] ([数値]))
を返し、そうでないなら[cell]で指定される[brd]の要素と[candidates]の差分に対して
    (([cannotbe] [差分_1])...([cannotbe] [差分_n]))
を返す。

例) [r4c6]=(1 3 6)のとき (mustbe (1 3))==>(cannotbe 6) と変換する。"
  (let (contents (result nil))
    (setf contents (aref brd (first cell) (second cell)))
    (cond
      ((atom contents)
       ;;(push (list 'mustbe (list contents)) result))
       (push (list 'mustbe contents) result))
      ((= (length candidates) 1)
       (push (list 'mustbe candidates) result))
      ((> (length candidates) 1)
       (dolist (lst (set-difference contents candidates :test #'equal))
         ;;(push (list 'cannotbe (list lst)) result))))
         (push (list 'cannotbe lst) result))))
    (return-from cell-mustbe result)))

(defun reduce-nice-path-list (nice-path-list)
"開始点が異なるだけの本質的に同じnice loopをひとつにまとめ,短い順に整列したリストを返す。"
  (let (nice-path p (tmp-nice nil))

    ;; Nice pathを[list-lessp]が定義する「小さい」順にソート。
    (setf nice-path-list (sort (copy-seq nice-path-list) #'list-lessp))

    (loop
       (if (null nice-path-list) (return))
       (setf nice-path (pop nice-path-list))
       (push nice-path tmp-nice)
       (loop
          (setf p (first nice-path-list))
          (cond
            ((> (length p) (length nice-path))
             (return))
            ((equal-nice-path-p nice-path p)
             (pop nice-path-list))
            (t (return)))))

    (return-from reduce-nice-path-list (reverse tmp-nice))))

(defun list-lessp (list-1 list-2)
"リスト[list-1]が[list-2]より「小さい」とき[t]を返す。そうでなければ[nil]を返す。
・リスト同士の場合は短いリストを「小さい」と定義する。
・アトム同士の場合は印字名同士を[string<]で比較し[t]となる方を「小さい」と定義する。
・リストとアトムの場合はアトムの方を「小さい」と定義する。
・数字同士の場合は数値として小さい方を小さいと定義する。
・[list-1]が[nil]の場合は常に[t]を返す。"
  (cond
    ((null list-1) t)
    ((null list-2) nil)
    ((and (atom list-1) (atom list-2))
     (cond
       ((and (integerp list-1) (integerp list-2))
        (< list-1 list-2))
       ((and (integerp list-1) (not (integerp list-2))) t)
       ((and (integerp list-2) (not (integerp list-1))) nil)
       (t (string< (symbol-name list-1) (symbol-name list-2)))))
    ((and (atom list-1) (listp list-2)) t)
    ((and (listp list-1) (atom list-2)) nil)
    ((and (listp list-1) (listp list-2))
     (cond
       ((< (length list-1) (length list-2)) t)
       ((< (length list-2) (length list-1)) nil)
       ((equal list-1 list-2) nil)
       ((equal (car list-1) (car list-2))
        (list-lessp (cdr list-1) (cdr list-2)))
       ((list-lessp (car list-1) (car list-2)) t)
       (t nil)))))

(defun equal-nice-path-p (path-0 path-1)
"パス[path-0]と[path-1]が Nice Loopとして等しいかどうかを返す。
[nice-path]::= ({continuous|discontinuous} ([cell-0] [inf-type] [label] [cell-1])...) ;"
  (cond
    ((not (equal (first path-0) (first path-1))) nil)
    ((and (equal (first path-0) 'continuous) (equal (first path-1) 'continuous))
     (cond
       ((equal (cdr path-0) (cdr path-1)) t)
       ((equal-if-rotate (cdr path-0) (cdr path-1)) t)
       ((equal-if-rotate (reverse-node-list (cdr path-0)) (cdr path-1)) t)
       (t nil)))
    ((and (equal (first path-0) 'discontinuous) (equal (first path-1) 'discontinuous))
     (cond
       ((equal (cdr path-0) (cdr path-1)) t)
       ((equal (cdr path-0) (reverse-node-list (cdr path-1))) t)
       (t nil)))
    (t nil)))

(defun equal-if-rotate (list-0 list-1)
"リスト[list-0]と[list-1]のどちらかのリストを回転させることで双方が等しくなるなら[t]を返す。

(equal-if-rotate '(a b c d e f) '(c d e f a b)) ==> t
(equal-if-rotate '(a b c d e f) '(a b c d e f)) ==> t
(equal-if-rotate '(a b c d e f) '(a b d c e f)) ==> nil"
  (let (node-0 pos)
    (setf node-0 (first list-0))
    (setf pos (position node-0 list-1 :test #'equal))
    (cond
      ((null pos) nil)
      ((zerop pos) (equal list-0 list-1))
      ((equal list-0 (rotate-list-left pos list-1)))
      ((equal list-0 (rotate-list-left (- (length list-1) (+ pos 1)) list-1)))
      (t nil))))

(defun reverse-node-list (node-list)
"[node-list] ::= ( [node]... ) ;
[node]      ::= ([cell-0] [inf-type] [label] [cell-1]) ;"
  (let ((stack nil))
    (dolist (node node-list)
      (push (list (nth 3 node) (nth 1 node) (nth 2 node) (nth 0 node)) stack))
    (return-from reverse-node-list stack)))

(defun rotate-list-left (n lst)
"リスト[lst]を左方向に[n]回回転する。[n]はリスト[lst]の長さより大きな数でもよい。

(rotate-list-left 2 '(a b c d e f)) ==> (c d e f a b)
(rotate-list-left 0 '(a b c d e f)) ==> (a b c d e f)
(rotate-list-left 6 '(a b c d e f)) ==> (a b c d e f)
(rotate-list-left 7 '(a b c d e f)) ==> (b c d e f a)"
  (let (num (tmp nil))
    (cond
      ((not (integerp n))
       (return-from rotate-list-left nil))
      (t (setf num (mod n (length lst)))))
    (if (zerop num) (return-from rotate-list-left lst))
    (dotimes (i num) (push (pop lst) tmp))
    (setf lst (append tmp (reverse lst)))
    (return-from rotate-list-left (reverse lst))))

(defun adj-cells (graph cell)
"指定されたセル[cell]の隣接リストのセル・アドレスのリストを返す。"
  (mapcar #'first (vertex-adj-list (aref graph (first cell) (second cell)))))

(defun adj-info (graph cell-0 cell-1)
"セル[cell-0]とセル[cell-1]のあいだの関係を返す。関係がなければ[nil]を返す。
[返り値]   ::= [adj-node] ;
[adj-node] ::= ([vertex] [weight] [inference type] [(label..)]) | [nil] ;"
  (let (a-list)
    (setf a-list (copy-seq (vertex-adj-list (aref graph (first cell-0) (second cell-0)))))
    (setf a-list (sort (copy-seq a-list) #'adj-list-less-p))
    ;;(format t "~%vertex-adj-list(after sorted) = ~s~%" a-list)
    (dolist (node a-list)
      (if (equal (get-vertex node) cell-1) (return-from adj-info node)))
    (return-from adj-info nil)))

(defun get-vertex (adj-node)
  (nth 0 adj-node))

(defun get-weight (adj-node)
  (nth 1 adj-node))

(defun get-inf (adj-node)
  (nth 2 adj-node))

(defun get-labels (adj-node)
  (nth 3 adj-node))

(defun get-all-labels (graph cell-0 cell-1)
  (let (link-0 link-1)
    (setf link-0 (get-labels (adj-info graph cell-0 cell-1)))
    (setf link-1 (get-labels (adj-info graph cell-1 cell-0)))
    (return-from get-all-labels (union link-0 link-1))))

(defun nice-p (graph inf-0 label-0 cell-0 cell-1)
"セル[cell-0]からのInference typeが[inf-1],ラベルが[label-1]であるセル[cell-1]から,
セル[cell-2]へnice loop連鎖ルールを満たすリンクが存在すれば[cell-2]へのinference typeと
ラベル値のペアをセットにしたリストのリストを返す。そうでなければ[nil]を返す。

(inf-1 label-1 [cell-1] [cell-2]) ==> ( ([cell-1] inf-2 label-2 [cell-2])... )

Nice loop連鎖ルール:
 (1) strong inferenceはweak inferenceとしても利用できる。
 (2) strong inferenceからstrong inferenceにループを延長するときは
     ラベルが異なっていなければならない。
 (3) weak inferenceからweak inferenceにループを延長するときはラベルが異なって
     いなければならず,延長元のセルは2値でなければならない。
 (4) strong inferenceからweak inference,またはその逆にループを延長するときは
     符号が異なる同じ値のラベルでなければならない。"
  (let (adj-list-1 inf-1 label-1 bival-link result rule-code info (result-list nil))

    (when (debug-write-p "nice-p")
      (format t "~%(nice-p [graph] ~s ~s ~a ~a)~%"
              inf-0 label-0 (cell-addr cell-0)  (cell-addr cell-1)) )

    (if (not (have-link-p graph cell-0 cell-1)) (return-from nice-p nil))

    ;; [cell-0]と[cell-1]がbi-value linkかどうかを調べておく。
    ;; 二つのセルがbi-value linkとは,
    ;;  ・[cell-0]が2値であり,
    ;;  ・[cell-0]と[cell-1]がリンクしており,
    ;;  ・共通の候補を持つこと。
    (setf bival-link (bivalue-link-p graph cell-0 cell-1))

    (when (debug-write-p "nice-p-bival")
      (format t "bi-value-link([~a]<-->[~a])=~s~%"
              (cell-addr cell-0) (cell-addr cell-1) bival-link))

    ;;[adj-list]        ::=([node]...)
    ;;[node]            ::=([vertex] [weight] [inference type] [(label..)])
    (setf adj-list-1 (vertex-adj-list (aref graph (first cell-1) (second cell-1))))

    (when (debug-write-p "nice-p(1)")
      (format t "adj-list-1(~a)=~a~%" (cell-addr cell-1) (adj-list-cell-addr adj-list-1)) )

    (dolist (node adj-list-1)

      (when (debug-write-p "nice-p(1)")
        (format t "node=~a~%" (append (list (cell-addr (get-vertex node))) (rest node))) )

      (when (equal (get-vertex node) cell-0)
        (setf inf-1 (get-inf node) label-1 (get-labels node))

        (when (debug-write-p "nice-p(2)")
          (format t "(inf-1 label-0 label-1)=(~s ~s ~s)~%" inf-1 label-0 label-1) )

        ;;Nice Loop開始セルの特例。
        (when (and (null inf-0) (null label-0))
          (dolist (i label-1)
            (cond
              ((equal inf-1 'strong)
               ;;(push (list cell-0 'weak (weak-label (list i)) cell-1) result-list)
               (push (list cell-0 'strong (strong-label (list i)) cell-1) result-list))
              ((equal inf-1 'weak)
               (push (list cell-0 'weak (weak-label (list i)) cell-1) result-list))))
          (when (debug-write-p "nice-p")
            (format t "開始セルの特例により nice-p returns ~s~%" (list result)) )
          (return-from nice-p result-list))

        (setf result (nice-p-sub inf-0 inf-1 label-0 label-1 bival-link))

        (dolist (i result)
          (setf info (first i) rule-code (second i))
          (setf result (append (list cell-0) info (list cell-1)))
          (push result result-list)
          (when (debug-write-p "nice-p(3)")
            (cond
              ((= rule-code 0) nil)
              ((< 0 rule-code 10)
               (format t "ルール(~d)により " rule-code))
              ((>= rule-code 10)
               (format t "ルール(~d+~d)により " (floor rule-code 10) (mod rule-code 10))))
            (format t "nice-p-sub returns ~a~%" info))) ) )

    (when (debug-write-p "nice-p")
      (format t "nice-p returns ~s~%" result-list))

    (return-from nice-p result-list)))

(defun nice-p-sub (inf-0 inf-1 label-0 label-1 bival-link)
  (let (result rule-code aim-label result-list)
    (setf result nil rule-code 0 result-list nil)
    (cond
      ;;[cell-0]はstrong inference。
      ((equal inf-0 'strong)
       (when (and ;;[cell-1]のstrong inferenceをstrongと解釈。==>rule(2)
              (equal inf-1 'strong)
              (setf aim-label (set-difference (strong-label label-1) (strong-label label-0))))
         (dolist (naked-label aim-label)
           (setf rule-code 2)
           (setf result (list 'strong (strong-label (list naked-label))))
           (push (list result rule-code) result-list)) )
       (when (and ;;[cell-1]のstrong inferenceをweakと解釈。==>rule(1+4)
              (equal inf-1 'strong)
              (setf aim-label (intersection (abs-label label-1) (strong-label label-0))))
         (dolist (naked-label aim-label)
           (setf rule-code 14)
           (setf result (list 'weak (weak-label (list naked-label))))
           (push (list result rule-code) result-list)))
       (when (and ;;[cell-1]はweak inference(ラベルは負)。==>rule(4)
              (equal inf-1 'weak)
              (setf aim-label (intersection (abs-label label-1) (strong-label label-0))))
         (dolist (naked-label aim-label)
           (setf rule-code 4)
           (setf result (list 'weak (weak-label (list naked-label))))
           (push (list result rule-code) result-list))) )
      ;;[cell-0]はweak inference。
      ((equal inf-0 'weak)
       (when (and ;;[cell-1]のstrong inferenceをstrongと解釈。==>rule(4)
              (equal inf-1 'strong)
              (setf aim-label (intersection (strong-label label-1) (abs-label label-0))))
         (dolist (naked-label aim-label)
           (setf rule-code 4)
           (setf result (list 'strong (strong-label (list naked-label))))
           (push (list result rule-code) result-list)))
       (when (and ;;[cell-1]のstrong inferenceをweakと解釈。==>rule(1+3)
              (equal inf-1 'strong)
              (setf aim-label (set-difference (abs-label label-1) (abs-label label-0)))
              (identity bival-link))
         (dolist (naked-label aim-label)
           (setf rule-code 13)
           (setf result (list 'weak (weak-label (list naked-label))))
           (push (list result rule-code) result-list)))
       (when (and ;;[cell-1]はweak inference(ラベルは負)。==>rule(3)
              (equal inf-1 'weak)
              (setf aim-label (set-difference (abs-label label-1) (abs-label label-0)))
              (identity bival-link))
         (dolist (naked-label aim-label)
           (setf rule-code 3)
           (setf result (list 'weak (weak-label (list naked-label))))
           (push (list result rule-code) result-list))))
      (t (error "can't happen at nice-p-sub.")))
    (return-from nice-p-sub result-list)))

(defun abs-label (label)
"リスト内のラベルを絶対値化したリストを返す。
[label] ::= ( [number]... ) ;"
  (let ((lst nil))
    (dolist (n label) (push (abs n) lst))
    (return-from abs-label (reverse lst))))

(defun strong-label (label)
"リスト内のラベルをstrong inference用に正の値にしたリストを返す。"
  (abs-label label))

(defun weak-label (label)
"リスト内のラベルをweak inference用に負の値にしたリストを返す。"
  (let ((lst nil))
    (dolist (n label) (push (- (abs n)) lst))
    (return-from weak-label (reverse lst))))

(defun do-bb-plot (brd)
"bi-value/bi-location plot(b/b plot)

(1) strong inferenceをstrong linkとして使うときは辺を実線で,
    ラベルを「+数字」または単に「数字」形式で書く。
(2) weak inferenceは辺を破線で、ラベルを「-数字」形式で書く。
(3) ユニット内の二択関係にある2所(bilocation)ノード間を実線で結ぶ。
(4) ユニット内で共通の数字候補を持つ2値(bivalue)ノード間を破線で結ぶ。
(5) ユニット内の実線を持つノードのラベル同士が一致していたらそのノード間を破線で結ぶ。
(6) ユニット内の実線を持つノードからノードのラベルと同じ候補を持つ2値ノードへ破線を描く。
(7) Nice loopが成立しているか判定する。必要であれば破線を追加(手順8と9を参照)して完成させる。
(8) 実線を持つノードにノードのラベルと共通の候補数字を持つ同じユニット内の任意のノードから
    破線を追加しても良い。
(9) 2値ノードに対して共通の候補数字を持つユニット内の任意のノードから破線を追加しても良い。

以上の手続きで接続されたセル同士は「リンク」の定義を満たしている。"
  (let (graph)
;   (setf graph (make-array (list *board-size* *board-size*) :initial-element nil))
    (setf graph (make-graph))
    (setf graph (find-bilocation brd graph))     ;B/B Plot rule (3).
    (setf graph (find-bivalue brd graph))        ;B/B Plot rule (4).
    (setf graph (find-same-label graph))         ;B/B Plot rule (5).
    (setf graph (find-same-candidate brd graph)) ;B/B Plot rule (6).
    (setf graph (bb-plot-opt-1 brd graph))       ;B/B Plot rule (8).
    (setf graph (bb-plot-opt-2 brd graph))       ;B/B Plot rule (9).
    (setf graph (mark-bivalue-cell brd graph))
    (setf graph (eliminate-edge-node graph))
    (return-from do-bb-plot (cleanup-graph-status graph))))

(defun find-bilocation (brd graph)
"ボード[brd]内のbilocationセルを実線(strong inference)で接続する。
接続関係を構造体vertexの2次元配列[graph]に追記した結果を返す。"
  (setf graph (find-bilocation-kernel brd graph 'row))
  (setf graph (find-bilocation-kernel brd graph 'col))
  (setf graph (find-bilocation-kernel brd graph 'block))
  (return-from find-bilocation graph))

(defun find-conjugate-pair-for (brd graph num &optional (cell-range nil))
"ボード[brd]内の候補数字[num]に対するconjugate pair(共役ペア)を探してグラフ[graph]に追加する。
[cell-range]が指定されている場合は[cell-range]の要素と接続しているbilocation cell
だけを[graph]に追加する。2番目の返り値として追加したセルのリスト[cells-added]を返す。"
  (let ((cells nil) cells-added)
    (multiple-value-setq
        (graph cells-added) (find-bilocation-kernel brd graph 'row num cell-range))
    (setf cells (union (copy-seq cells-added) cells :test #'equal))
    (multiple-value-setq
        (graph cells-added) (find-bilocation-kernel brd graph 'col num cell-range))
    (setf cells (union (copy-seq cells-added) cells :test #'equal))
    (multiple-value-setq
        (graph cells-added) (find-bilocation-kernel brd graph 'block num cell-range))
    (setf cells (union (copy-seq cells-added) cells :test #'equal))
    (setf cells (sort (copy-seq cells) #'cell-order-p))
    (return-from find-conjugate-pair-for (values graph cells))))

(defun find-bilocation-kernel (brd graph kind &optional (num nil) (cell-range nil))
"[num]が指定されている場合は[num]に対するbilocation cellを[graph]に追加する。
[cell-range]が指定されている場合は[cell-range]の要素と接続しているbilocation cell
だけを[graph]に追加する。2番目の返り値として追加したセルのリスト[cells-added]を返す。"
  (let (row-base col-base row-in-blk col-in-blk candidates cells-added rc-f rc-s tmp)
    (setf candidates (make-array *board-size*))
    (setf cells-added nil)
    (dotimes (i *board-size*)
      (dotimes (n *board-size*)
        (setf (aref candidates n) nil))
      (when (equal kind 'block)
        (setf row-base (block-base-row i))
        (setf col-base (block-base-col i)))
      (dotimes (j *board-size*)
        (cond
          ((equal kind 'row)            ;[i]行に対して列[j]を集計。
           (setf tmp (aref brd i j))
           (when (pure-listp tmp)
             (dolist (k tmp)
               (push (list i j) (aref candidates (position k *np-digit*))))))
          ((equal kind 'col)            ;[i]列に対して行[j]を集計。
           (setf tmp (aref brd j i))
           (when (pure-listp tmp)
             (dolist (k tmp)
               (push (list j i) (aref candidates (position k *np-digit*))))))
          ((equal kind 'block)          ;ブロック[i]の要素を集計。
           (setf row-in-blk (+ row-base (floor j *block-size*)))
           (setf col-in-blk (+ col-base (mod j *block-size*)))
           (setf tmp (aref brd row-in-blk col-in-blk))
           (when (pure-listp tmp)
             (dolist (k tmp)
               (push (list row-in-blk col-in-blk) (aref candidates (position k *np-digit*))))))
          (t (error "can't happen at find-bilocation-kernel."))) )
      (dotimes (j *board-size*)
        (setf tmp (reverse (aref candidates j)))
        (when (= (length tmp) 2)
          (setf rc-f (member (first tmp) cell-range :test #'equal))
          (setf rc-s (member (second tmp) cell-range :test #'equal))
          ;;(format t "rc-f = ~s, rc-s = ~s, " (not (null rc-f)) (not (null rc-s)))
          ;;(format t "num = ~d, (aref candidates ~d) = ~s~%" num j tmp)
          (cond
            ((and
               (null num)
               (null cell-range))
              (setf cells-added (union (list (first tmp)) cells-added :test #'equal))
              (setf cells-added (union (list (second tmp)) cells-added :test #'equal))
              (when (debug-write-p "find-bilocation-kernel")
                (format t "1.(make-bilocation-link [gr] ~s ~s ~d)~%" (car tmp) (cadr tmp) (1+ j)) )
              (setf graph (make-bilocation-link graph (first tmp) (second tmp) (1+ j))))
            ((and
               (integerp num)
               (= (1+ j) num)
               (null cell-range))
              (setf cells-added (union (list (first tmp)) cells-added :test #'equal))
              (setf cells-added (union (list (second tmp)) cells-added :test #'equal))
              (when (debug-write-p "find-bilocation-kernel")
                (format t "2.(make-bilocation-link [gr] ~s ~s ~d)~%" (car tmp) (cadr tmp) num) )
              (setf graph (make-bilocation-link graph (first tmp) (second tmp) num)))
            ((and
               (null num)
               (identity cell-range)
               (or rc-f rc-s))
              (cond
                ((identity rc-f)
                  (setf cells-added (union (list (second tmp)) cells-added :test #'equal)))
                ((identity rc-s)
                  (setf cells-added (union (list (first tmp)) cells-added :test #'equal))))
              (when (debug-write-p "find-bilocation-kernel")
                (format t "3.(make-bilocation-link [gr] ~s ~s ~d)~%" (car tmp) (cadr tmp) (1+ j)) )
              (setf graph (make-bilocation-link graph (first tmp) (second tmp) (1+ j))))
            ((and
               (integerp num)
               (= (1+ j) num)
               (identity cell-range)
               (or rc-f rc-s))
              (cond
                ((identity rc-f)
                  (setf cells-added (union (list (second tmp)) cells-added :test #'equal)))
                ((identity rc-s)
                  (setf cells-added (union (list (first tmp)) cells-added :test #'equal))))
              (when (debug-write-p "find-bilocation-kernel")
                (format t "4.(make-bilocation-link [gr] ~s ~s ~d)~%" (car tmp) (cadr tmp) num) )
              (setf graph (make-bilocation-link graph (first tmp) (second tmp) num)))
            (t (do-nothing))))))
    (setf cells-added (sort (copy-seq cells-added) #'cell-order-p))
    (when (debug-write-p "find-bilocation-kernel")
      (format t "find-bilocation-kernel: num = ~s, kind = ~s~%" num kind)
      (format t "find-bilocation-kernel: cells-added = ~s~%" cells-added)
      (force-output) )
    (return-from find-bilocation-kernel (values graph cells-added))))

(defun make-bilocation-link (graph cell-1 cell-2 label)
    (setf graph (make-strong-link graph cell-1 cell-2 label))
    (return-from make-bilocation-link graph))

(defun make-bivalue-link (graph cell-1 cell-2 label)
  (setf graph (make-weak-link graph cell-1 cell-2 label))
  (return-from make-bivalue-link graph))

(defun make-strong-link (graph cell-1 cell-2 label)
"セル[cell-1]と[cell-2]をstrong inferenceでリンクする。"
  (cond
    ((pure-listp label)
     (setf label (strong-label label)))
    ((integerp label)
     (setf label (strong-label (list label))))
    (t (error "can't happen at make-strong-link.")))
  (setf graph (link-cells graph cell-1 cell-2 (dist cell-1 cell-2) 'strong label))
  (return-from make-strong-link graph))

(defun make-weak-link (graph cell-1 cell-2 label)
"セル[cell-1]と[cell-2]をweak inferenceでリンクする。
ラベルを負の値として登録。2009/05/13"
  (cond
    ((pure-listp label)
     (setf label (weak-label label)))
    ((integerp label)
     (setf label (weak-label (list label))))
    (t (error "can't happen at make-weak-link.")))
  (setf graph (link-cells graph cell-1 cell-2 (dist cell-1 cell-2) 'weak label))
  (return-from make-weak-link graph))

(defun link-cells (graph cell-1 cell-2 weight inf-type label)
"[cell-1]と[cell-2]の双方向リンクを作成する。"
  (setf graph (link-cells-one-way graph cell-1 cell-2 weight inf-type label))
  (setf graph (link-cells-one-way graph cell-2 cell-1 weight inf-type label))
  (return-from link-cells graph))

(defun link-cells-one-way (graph cell-1 cell-2 weight inf-type label)
"[cell-1]から[cell-2]への片方向リンクを作成する。セルのデータ形式は[(row col)]。
ラベル[label]だけが異なればラベルだけを「追加」登録する。
[cell-1]から[cell-2]へのリンクが存在しないなら、新たにリンクを作成する。
そうでないなら何もしない(同じセル間に同内容で複数のリンクを作らない)。"
  (let (row-1 col-1 adj new-labels tmp)
    (setf row-1 (first cell-1) col-1 (second cell-1))
    (if (atom label) (setf label (list label)))
    (when (debug-write-p "link-cells-one-way")
      (if (typep (aref graph row-1 col-1) 'vertex)
          (format t "~s:adj-list=~s~%" cell-1 (vertex-adj-list (aref graph row-1 col-1)))
          (format t "~s:adj-list=~s~%" cell-1 (aref graph row-1 col-1)))
      (format t "~s+param   =~s~%" cell-2 (list cell-2 weight inf-type label)))
    (cond
      ;;構造体が作成されていなければ新たに作成する。
      ((null (aref graph row-1 col-1))
       (setf (aref graph row-1 col-1)
             (make-vertex
              :fringe-weight (max-weight)
              ;;[adj-list]::=([node]...)
              ;;[node]::=([vertex] [weight] [inference type] [(label..)])
              :adj-list (list (list cell-2 weight inf-type label))))
       (when (debug-write-p "link-cells-one-way")
         (format t "構造体を新たに作成します。~%")
         (format t "結果は~sです。~%" (vertex-adj-list (aref graph row-1 col-1))))
       )
      ;;すでに構造体が用意されていれば...
      ((typep (aref graph row-1 col-1) 'vertex)
       (cond
         ;;[cell-1]から[cell-2]へのリンクが存在しないなら新しいリンクを作成する。
         ((not (have-one-way-link-p graph cell-1 cell-2))
          (push (list cell-2 weight inf-type label)
                (vertex-adj-list (aref graph row-1 col-1)))
          (when (debug-write-p "link-cells-one-way")
            (format t "構造体は存在しますが~sから~sへのリンクが存在しません。~%" cell-1 cell-2)
            (format t "結果は~sです。~%" (vertex-adj-list (aref graph row-1 col-1))))
          )
         ;;[cell-1]から[cell-2]へのリンクが存在する。
         (t ;既存のリンクとラベルだけが異なるならラベルだけを追加する。そうでなければ何もしない。
          (setf adj (vertex-adj-list (aref graph row-1 col-1)))
          (setf tmp nil)
          (dolist (node adj)
            (when (same-node-but-label-p node (list cell-2 weight inf-type label))
              ;;ラベルはソートしておく。
              (setf new-labels (list (sort (union label (first (last node))) #'<)))
              (setf node (append (butlast node) new-labels)))
            (push node tmp))
          (setf (vertex-adj-list (aref graph row-1 col-1)) (reverse tmp))
          (when (debug-write-p "link-cells")
            (format t "ラベルだけが異なる条件での処理です。~%")
            (format t "結果は~sです。~%" (vertex-adj-list (aref graph row-1 col-1)))))
         ))
      (t (error "can't happen at link-cells.")))
    (return-from link-cells-one-way graph)))

(defun delete-link (graph cell-0 cell-1)
"セル[cell-0]とセル[cell-1]の間の隣接リストによるリンク関係を消去する。"
  (let (adj-list-0 adj-list-1 adj-list)
    (when (have-link-p graph cell-0 cell-1)
       (setf adj-list-0 (vertex-adj-list (aref graph (first cell-0) (second cell-0))))
       (setf adj-list-1 (vertex-adj-list (aref graph (first cell-1) (second cell-1))))
       (setf adj-list nil)
       (dolist (adj-0 adj-list-0)
         (if (not (equal (get-vertex adj-0) cell-1)) (push adj-0 adj-list)))
       (setf (vertex-adj-list (aref graph (first cell-0) (second cell-0))) adj-list)
       (setf adj-list nil)
       (dolist (adj-1 adj-list-1)
         (if (not (equal (get-vertex adj-1) cell-0)) (push adj-1 adj-list)))
       (setf (vertex-adj-list (aref graph (first cell-1) (second cell-1))) adj-list))
    (return-from delete-link graph)))

(defun have-one-way-link-p (graph cell-1 cell-2)
"[cell-1]から[cell-2]に片方向リンクが存在すれば[t]、そうでなければ[nil]を返す。"
  (let (adj vtx result)
    (when (debug-write-p "have-one-way-link-p")
      (format t "(have-one-way-link-p graph ~s ~s)~%" cell-1 cell-2))
    (if (or (null cell-1) (null cell-2)) (return-from have-one-way-link-p nil))
    (if (equal cell-1 cell-2) (return-from have-one-way-link-p t))
    (setf vtx (aref graph (first cell-1) (second cell-1)))
    (if (typep vtx 'vertex) (setf adj (vertex-adj-list vtx))
        (return-from have-one-way-link-p nil))
    (setf result nil)
    (dolist (p adj)
      (if (equal cell-2 (get-vertex p)) (setf result t)))
    (return-from have-one-way-link-p result)))

(defun have-link-p (graph cell-1 cell-2)
"[cell-1]から[cell-2]に双方向リンクが存在すれば[t]、そうでなければ[nil]を返す。"
  (and
   (have-one-way-link-p graph cell-1 cell-2)
   (have-one-way-link-p graph cell-2 cell-1)))

(defun same-node-but-label-p (node-1 node-2)
"[node-1]と[node-2]がラベル(=末尾)以外が同じならば[t]、そうでなければ[nil]を返す。
[node] ::= ([vertex] [weight] [inference type] [(label..)]) | [nil] ;"
  (let (result)
    (setf result
          (and (equal (butlast node-1) (butlast node-2))
               (not (set-equal (last node-1) (last node-2)))))
    (return-from same-node-but-label-p result)))

(defun find-bivalue (brd graph)
  (setf graph (find-bivalue-kernel brd graph 'row))
  (setf graph (find-bivalue-kernel brd graph 'col))
  (setf graph (find-bivalue-kernel brd graph 'block))
  (return-from find-bivalue graph))

(defun find-bivalue-kernel (brd graph kind)
  (let (row-base col-base row-in-blk col-in-blk candidate cells cell-0 cell-1 tmp)
    (dotimes (i *board-size*)
      (setf cells nil)
      (when (equal kind 'block)
        (setf row-base (block-base-row i))
        (setf col-base (block-base-col i)))
      (dotimes (j *board-size*)
        (cond
          ((equal kind 'row) ;行内の2値ノード・アドレスを[cells]に追加。
           (setf tmp (aref brd i j))
           (when (and (pure-listp tmp) (= (length tmp) 2))
             (push (list i j) cells)))
          ((equal kind 'col) ;列内の2値ノード・アドレスを[cells]に追加。
           (setf tmp (aref brd j i))
           (when (and (pure-listp tmp) (= (length tmp) 2))
             (push (list j i) cells)))
          ((equal kind 'block) ;ブロック内の2値ノード・アドレスを[cells]に追加。
           (setf row-in-blk (+ row-base (floor j *block-size*)))
           (setf col-in-blk (+ col-base (mod j *block-size*)))
           (setf tmp (aref brd row-in-blk col-in-blk))
           (when (and (pure-listp tmp) (= (length tmp) 2))

             (push (list row-in-blk col-in-blk) cells)))
          (t (error "can't happen at find-bilocation-kernel."))) )

      ;;共通の候補を持つ2値ノードのペアを探しbi-value linkとする。
      (setf cells (reverse cells))
      (when (>= (length cells) 2)
        (dolist (pair (combination cells 2))
          (setf cell-0 (first pair) cell-1 (second pair))
          (setf candidate (intersection (aref brd (first cell-0) (second cell-0))
                                        (aref brd (first cell-1) (second cell-1))))
          (when candidate
            (when (debug-write-p "find-bivalue-kernel")
              (format t "~aと~aは~sを共通候補とする~sでのbi-valueセルです。~%"
                      (cell-addr cell-0) (cell-addr cell-1) candidate kind))
            (setf graph (make-bivalue-link graph cell-0 cell-1 candidate))))))
    (return-from find-bivalue-kernel graph)))

(defun mark-bivalue-cell (brd graph)
"グラフ[graph]内のbivalue cellにマークを付けておく。"
  (dotimes (i *board-size*)
    (dotimes (j *board-size*)
      (when (typep (aref graph i j) 'vertex)
        (cond
          ((and (pure-listp (aref brd i j)) (= (length (aref brd i j)) 2))
           (setf (vertex-bivalue-cell (aref graph i j)) (aref brd i j) ))
          (t (setf (vertex-bivalue-cell (aref graph i j)) nil))))))
  (return-from mark-bivalue-cell graph))

(defun bivalue-cell-p (graph cell)
  (let (i j)
    (setf i (first cell) j (second cell))
    (return-from bivalue-cell-p (vertex-bivalue-cell (aref graph i j)))))

(defun bivalue-link-p (graph cell-1 cell-2)
"セル[cell-0]と[cell-1]が bi-value linkかどうかを返す。

二つのセルがbi-value linkとは,
    ・[cell-1]と[cell-2]の間に辺があり,
    ・[cell-1]が2値であり,
    ・[cell-1]と[cell-2]が同じユニットに属し,
    ・共通の候補を持つこと。"
  (let (row-1 col-1 cand-1 row-2 col-2 (result nil))
    (when (debug-write-p "bivalue-link-p")
      (format t "(bivalue-link-p [graph] ~s ~s)~%" cell-1 cell-2))
    (if (or (null cell-1) (null cell-2)) (return-from bivalue-link-p nil))
    (setf row-1 (first cell-1) col-1 (second cell-1))
    (setf row-2 (first cell-2) col-2 (second cell-2))
    (when (and (typep (aref graph row-1 col-1) 'vertex) (typep (aref graph row-2 col-2) 'vertex))
      (setf cand-1 (vertex-bivalue-cell (aref graph row-1 col-1)))
      (setf result (and (have-link-p graph cell-1 cell-2) (identity cand-1) )))
    (when (debug-write-p "bivalue-link-p")
      (format t "bivalue-link-p returns ~s~%" result))
    (return-from bivalue-link-p result)))

(defun find-same-label (graph)
"グラフ[graph]内の2つのセルが
  (1) 共にstrong inferenceを持ち,
  (2) 同じユニット内で,
  (3) 同じラベルのノード同士
ならば,それぞれをweak linkする。"
  (let (cell-0 cell-1 label-0 label-1 (strong-cells nil))

    (dolist (p (get-strong-inf-cell graph))
      (setf strong-cells (append p strong-cells)))

    ;;strong inferenceを持つセルを抽出する。
    (let (i j (k 0) adj-list (tmp nil))
      (dolist (cell strong-cells)
        (setf i (first (first cell)) j (second (first cell)))
        ;;[adjeycency list]::=(([vertex] [weight] [inference type] [labels])...) ;
        (setf adj-list (vertex-adj-list (aref graph i j)))
        (dolist (adj adj-list)
          (if (equal (nth 2 adj) 'strong) (incf k)))
        ;;(if (= k 1) (push cell tmp)))
        (if (>= k 1) (push cell tmp)))
      (setf strong-cells (reverse tmp)))

    (dolist (pair (combination strong-cells 2))
      (setf cell-0 (first (first pair))  label-0 (second (first pair)))
      (setf cell-1 (first (second pair)) label-1 (second (second pair)))
      (when (and (same-unit-p cell-0 cell-1) (intersection label-0 label-1))
        (setf graph (make-weak-link graph cell-0 cell-1 (intersection label-0 label-1)))))

    (return-from find-same-label graph)))

(defun get-strong-inf-cell (graph)
"strong inferenceを持つセルをラベルとセットにして[result]に抽出する。
連結部分木のリストを返す。
  [result]          ::= ( [connected group]... ) ;
  [connected group] ::= ( [cell&label]... ) ;
  [cell&label]      ::= ( [cell] ([label]...) ) ;"
  (let (adj inf-type cgroup-list cgrp label result n)
    (setf result nil)
    (setf n 0)
    (setf cgroup-list (get-connected-group graph))
    ;;(setf cgroup-list (list (get-all-vertices graph)))
    (dolist (cgroup cgroup-list)
      (setf cgrp nil)
      (dolist (cell cgroup)
        (setf adj (vertex-adj-list (aref graph (first cell) (second cell))))
        (dolist (p adj)
          (setf inf-type (get-inf p))
          (debug-write "find-same-label" (format nil "~a's inf-type=~s" (cell-addr cell) inf-type))
          (when (equal inf-type 'strong)
            (setf label (get-labels p))
            (push (list cell label) cgrp)
            (incf n) )))
      (if (identity cgrp) (push cgrp result)))

    (when (debug-write-p "find-same-label")
      (format t "strong inferenceを持つセルを抽出しました:~s~%" result)
      (format t "頂点の数は~dでした。~%" n))

    (return-from get-strong-inf-cell result)))

(defun get-connected-group (graph)
"グラフ[graph]のすべての連結成分のリストを返す。
返り値 ::= ([連結成分]...) ;
[連結成分] ::= ([cell]...) ;"
  (let (p q result)
    (setf result nil)
    (loop
       (setf p (get-connected-group-sub graph))
       (setf q (first p) graph (second p))
       (if (null q) (return))
       (push q result))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (when (typep (aref graph i j) 'vertex)
          (setf (vertex-status (aref graph i j)) 'unseen)))) ;元の状態に戻しておく。
    (debug-write "get-connected-group" (format nil "result=~s" result))
    (return-from get-connected-group result)))

(defun get-connected-group-sub (graph)
"グラフ[graph]から(最小生成部分木を作成し)連結成分をひとつ返す。
[連結成分] ::= ([cell]...) ;
返り値 ::= ([連結成分] [graph]) ;"
  (let (n x y w row-x col-x row-y col-y adj-list result)

    (debug-write "get-connected-group-sub" (format nil "~%*** entered"))
    (setf n (count-vertices graph))
    (setf x (first-vertex graph))
    (if (null x) (return-from get-connected-group-sub (list nil graph)))
    (setf row-x (first x) col-x (second x))
    (setf (vertex-status (aref graph row-x col-x)) 'intree)

    (do ( (edge-count 0)
          (fringe-list nil)
          (stuck nil)
          (min-weight)
          (nearest-cell)
          (status)
          (weight)
          (fringe-weight) )
        ((or (>= edge-count (1- n)) stuck))

      (setf row-x (first x) col-x (second x))
      (debug-write "get-connected-group-sub" (format nil "x=~s" x))

      (setf adj-list (vertex-adj-list (aref graph row-x col-x)))
      ;;(setf adj-list (sort adj-list #'adj-list-less-p))
      (dolist (node adj-list)
        (setf y (get-vertex node))
        (setf row-y (first y) col-y (second y))
        (debug-write "get-connected-group-sub" (format nil "y=~s" y))
        (setf status (vertex-status (aref graph row-y col-y)))
        (setf fringe-weight (vertex-fringe-weight (aref graph row-y col-y)))
        (setf weight (get-weight node))
        ;;yの候補辺をxyに交換する。
        (when (and (equal status 'fringe) (< weight fringe-weight))
          (setf (vertex-parent (aref graph row-y col-y)) x)
          (setf (vertex-fringe-weight (aref graph row-y col-y)) weight))
        ;;yを縁点に加える。xyは候補辺。
        (when (equal status 'unseen)
          (setf (vertex-status (aref graph row-y col-y)) 'fringe)
          (push y fringe-list)
          (setf (vertex-parent (aref graph row-y col-y)) x)
          (setf (vertex-fringe-weight (aref graph row-y col-y)) weight)) ) ;;end dolist

      (debug-write "get-connected-group-sub" (format nil "fringe-list(1)=~s" fringe-list) )

      ;;木の次の点と辺を結ぶ。
      (cond
        ((identity fringe-list)
         ;;縁点リストをたどり重み最小の候補辺を見つける。
         (setf min-weight (max-weight))
         (dolist (cell fringe-list)
           (setf w (vertex-fringe-weight (aref graph (first cell) (second cell))))
           (when (< w min-weight)
             (setf nearest-cell cell min-weight w)))
         (setf x nearest-cell)
         (setf row-x (first x) col-x (second x))
         (debug-write "get-connected-group-sub" (format nil "nearest-cell=~s" nearest-cell) )
         ;;xを縁点リストから除去。
         (setf fringe-list (set-difference fringe-list (list x) :test #'equal))
         (debug-write "get-connected-group-sub" (format nil "fringe-list(2)=~s" fringe-list) )
         (setf (vertex-status (aref graph row-x col-x)) 'intree)
         (incf edge-count))
        (t (setf stuck t))) ) ;;end do

    (setf result nil)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (when (and (typep (aref graph i j) 'vertex)
                   (equal (vertex-status (aref graph i j)) 'intree))
          (setf (vertex-status (aref graph i j)) 'used)
          (push (list i j) result))))
    (setf result (reverse result))

    (when (debug-write-p "get-conncted-group-sub")
      (format t "get-connected-group-sub ==> ~s~%" result) )

    (return-from get-connected-group-sub (list result graph))))

(defun get-all-vertices(graph)
"グラフ[graph]のすべての頂点(他のセルへのリンクを持つセル)のアドレスを返す。"
  (let ((result nil))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (if (typep (aref graph i j) 'vertex) (push (list i j) result))))
    (return-from get-all-vertices (reverse result))))

(defun count-vertices (graph)
"リンクを持つ未走査頂点の数を返す。"
  (let (n)
    (setf n 0)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (if (and (typep (aref graph i j) 'vertex) (equal (vertex-status (aref graph i j)) 'unseen))
            (incf n) )))
    (return-from count-vertices n)))

(defun first-vertex (graph)
"リンクを持つ未走査頂点をひとつ返す。"
  (dotimes (i *board-size*)
    (dotimes (j *board-size*)
      (if (and (typep (aref graph i j) 'vertex) (equal (vertex-status (aref graph i j)) 'unseen))
          (return-from first-vertex (list i j))))))

(defun find-same-candidate (brd graph)
"グラフ[graph]内の
  (1) strong inferenceを持つセルと,
  (2) セルのラベルと同じ値の候補数字を持つ
  (3) 同じユニット内の2値ノードを
  (4) weak inferenceでリンクする。"
  (let (strong-cells bivalue-cells cell-0 label-0 cell-1 candidates common satisfy)

    ;;Bi-value(2値)ノードとそのラベルのペアをリストアップする。
    ;; [bivalue-cells] ::= ( ([cell] [labels])... ) ;
    (setf bivalue-cells nil)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf candidates (aref brd i j))
        (if (and (pure-listp candidates) (= (length candidates) 2))
            (push (list (list i j) candidates) bivalue-cells))))
    (setf bivalue-cells (reverse bivalue-cells))

    (when (debug-write-p "find-same-candidate")
      (format t "bivalue-cells=~s~%" bivalue-cells) )

    ;; strong inferenceを持つセルのリストを得る。
    ;; [get-strong-inf-cell] returns ( [connected group]... ) ;
    ;; [connected group]        ::= ( [cell&label]... ) ;
    ;; [cell&label]             ::= ( [cell] ([label]...) ) ;
    (dolist (p (get-strong-inf-cell graph))
      (setf strong-cells (append p strong-cells)))

    ;;strong inferenceを持つセルを抽出する。
    (let (i j (k 0) adj-list (tmp nil))
      (dolist (cell strong-cells)
        (setf i (first (first cell)) j (second (first cell)))
        ;;[adjeycency list]::=(([vertex] [weight] [inference type] [labels])...) ;
        (setf adj-list (vertex-adj-list (aref graph i j)))
        (dolist (adj adj-list)
          (if (equal (nth 2 adj) 'strong) (incf k)))
        ;;(if (= k 1) (push cell tmp)))
        (if (>= k 1) (push cell tmp)))
      (setf strong-cells (reverse tmp)))

    (when (debug-write-p "find-same-candidate")
      (format t "strong-cells=~s~%" strong-cells) )

    (dolist (strong-cell-info strong-cells)
      (setf cell-0 (first strong-cell-info) label-0 (second strong-cell-info))
      (dolist (bivalue-cell-info bivalue-cells)
        (setf cell-1 (first bivalue-cell-info) candidates (second bivalue-cell-info))
        (setf common (intersection label-0 candidates))
        (setf satisfy (and (not (equal cell-0 cell-1)) (not (have-link-p graph cell-0 cell-1))))
        (setf satisfy (and satisfy (same-unit-p cell-0 cell-1) (identity common)))

        (when satisfy
          (when (debug-write-p "find-same-candidate")
            (format t "find-same-candidate:条件が成立しました。~%")
            (format t "(same-unit-p ~s ~s)=~s~%" cell-0 cell-1 (same-unit-p cell-0 cell-1))
            (format t "(intersection ~s ~s)=~s~%~%" label-0 candidates common) )
          (setf graph (make-weak-link graph cell-0 cell-1 common)))))

    (return-from find-same-candidate graph)))

(defun bb-plot-opt-1 (brd graph)
"b/b plot追加的手順(1)
  1) strong inferenceを持つセルに,
  2) セルのラベルと共通の候補数字を持つ,
  3) 同じユニット内の任意のセルから,
  4) 破線(weak link)を追加しても良い。"
  (let ((strong-cells nil) strong-cell strong-label candidates common)
    
    ;; strong inferenceを持つセルのリストを得る。
    ;; [get-strong-inf-cell] returns ( [connected group]... ) ;
    ;; [connected group]        ::= ( [cell&label]... ) ;
    ;; [cell&label]             ::= ( [cell] ([label]...) ) ;
    (dolist (p (get-strong-inf-cell graph))
      (setf strong-cells (append p strong-cells)))

    (when (debug-write-p "bb-plot-opt-1")
      (format t "strong-cells=~s~%" strong-cells)
      (force-output))

    (dolist (pair strong-cells)
      (setf strong-cell (first pair) strong-label (second pair))
      (when (debug-write-p "bb-plot-opt-1")
        (format t "strong-cell=~s~%" strong-cell)
        (format t "同じユニットのセルは~sです。~%" (same-unit-cells strong-cell))
        (force-output))
      (dolist (any-cell (same-unit-cells strong-cell))
        (setf candidates (aref brd (first any-cell) (second any-cell)))
        (when (and (not (equal any-cell strong-cell)) (pure-listp candidates))
          (setf common (intersection candidates strong-label))
          (when common
            (when (debug-write-p "bb-plot-opt-1(2)")
              (format t "*** bb-plot-opt-1~%")
              (format t "~sと~sをweak linkします。ラベルは~sです。~%" strong-cell any-cell common)
              (force-output))
            (setf graph (make-weak-link graph strong-cell any-cell common))))))
    
    (return-from bb-plot-opt-1 graph)))

(defun bb-plot-opt-2 (brd graph)
"b/b plot追加的手順(2)
  1) 2値ノードに対して,
  2) 共通の候補数字を持つ,
  3) 同じユニット内の任意のノードから,
  4) 破線(weak link)を追加しても良い。"
  (let (bivalue-cells candidates common bc-candidates ac-candidates)

    ;;Bi-value(2値)ノードをリストアップする。
    ;; [bivalue-cells] ::= ( [cell]... ) ;
    (setf bivalue-cells nil)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf candidates (aref brd i j))
        (if (and (pure-listp candidates) (= (length candidates) 2))
            (push (list i j) bivalue-cells))))
    (setf bivalue-cells (reverse bivalue-cells))

    (when (debug-write-p "bb-plot-opt-2")
      (format t "bivalue-cells=~s~%" bivalue-cells))

    (dolist (bivalue-cell bivalue-cells)
      (when (debug-write-p "bb-plot-opt-2")
        (format t "bivalue-cell=~s~%" bivalue-cell))
      (dolist (any-cell (same-unit-cells bivalue-cell))
        (when (debug-write-p "bb-plot-opt-2")
          (format t "any-cell=~s~%" any-cell) )
        (setf ac-candidates (aref brd (first any-cell) (second any-cell)))
        (when (and (not (equal any-cell bivalue-cell)) (not (atom ac-candidates)))
          (setf bc-candidates (aref brd (first bivalue-cell) (second bivalue-cell)))
          (setf common (intersection ac-candidates bc-candidates))
          (when common
            (when (debug-write-p "bb-plot-opt-2(2)")
              (format t "bb-plot-opt-2: ")
              (format t "~sと~sをweak linkします。ラベルは~sです。~%" bivalue-cell any-cell common)
              (force-output))
            (setf graph (make-weak-link graph bivalue-cell any-cell common))) )))

    (return-from bb-plot-opt-2 graph)))

;;; 端点(リンクをひとつしか持たない頂点)はループ構成要素になり得ないので削除する。
(defun eliminate-edge-node (graph)
  (let (new-graph adj-list)
;   (setf new-graph (make-array (list *board-size* *board-size*) :initial-element nil))
    (setf new-graph (make-graph))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (when (typep (aref graph i j) 'vertex)
          (cond
            ((> (length (vertex-adj-list (aref graph i j))) 1)
             (setf (aref new-graph i j) (make-vertex))
             (setf (aref new-graph i j) (aref graph i j)))
            ((= (length (vertex-adj-list (aref graph i j))) 1)
             ;;[adj-list]::=([node]...)
             ;;[node]::=([vertex] [weight] [inference type] [(label..)])
             (setf adj-list (vertex-adj-list (aref graph i j)))
             (setf graph (delete-link graph (list i j) (get-vertex (first adj-list))))
             (setf (aref new-graph i j) nil))))))
    (return-from eliminate-edge-node new-graph)))

(defun do-advanced-coloring (board)
  "Advanced Coloring (3D Medusa)の実装

Definition: Conjugate pair
A conjugate pair is a pair of candidates with a strong link.
They are the last 2 candidates for a single digit in a house they share.

Different terms were introduced for the same concept when the Sudoku community developed their
solving techniques. The term conjugate pair is mainly used in coloring techniques.
The term strong link refers to the link between 2 candidates, but does not include the
candidates themselves, whereas the term conjugate pair clearly refers to the candidates.
Furthermore, a strong link can also exist between the last 2 candidates in a single cell,
but it is not customary to call these 2 candidates a conjugate pair.
There is also a difference between a conjugate pair and a connected pair.
In a conjugate pair, only one of the two candidates in the house can be true.
In a connected pair, at least one of the candidates must be true, but it is also possible
that both of them are true. The only certainty we have about a connected pair is that they
cannot both be false at the same time.

From Sudopedia (http://www.sudopedia.org/wiki/Main_Page)."
  (let (brd pmode info-list)
    (when (< (bivalue-cell-ratio board) (advanced-ratio))
      (return-from do-advanced-coloring board)
      ) ;; end when
    (setf brd (new-board board))
    (setf pmode (pencil-mark)) ;; 現在のペンシル・マーク・モードを保存。
    (setq info-list nil)
    (cond
      ((or
        (= (color-mode) 0)
        (= (color-mode) 1))
       (pencil-mark t) ;; ペンシル・マーク・モードをオンにする。
       )
      (t
       (do-nothing)
       )
      ) ;; end cond
    (record-quiz-info :function-name 'do-advanced-coloring)
    (multiple-value-setq (brd info-list) (do-advanced-coloring-sub brd)) ;; ペンシル・マーク・モード必須。
    (pencil-mark pmode) ;; ペンシル・マーク・モードを復元する。
    (return-from do-advanced-coloring (values (clean-up-board brd) info-list))
    ) ;; end let
  ) ;; end do-advanced-coloring

(defun do-advanced-coloring-sub (brd)
  (let (elm-brd color-brd info-list info-list-list planes elm-list)
    (setf elm-brd (new-board brd))
    (setf color-brd (new-board brd))
    (setq info-list-list nil)
    #|
    (do*
     ((planes (do-coloring brd) (do-coloring brd))
      (elm-list (analyze-cluster planes) (analyze-cluster planes)))
     ((null elm-list) nil)
    |#
    (loop
      (setq planes (do-coloring brd))
      (multiple-value-setq (elm-list info-list) (analyze-cluster planes)) ;; 2024-04-29
      (if (identity info-list)
	  (push info-list info-list-list)
	  ) ;; end if
      (if (null elm-list)
	  (return) ;; exit this loop.
	  )	   ;; end inf

      (when (debug-write-p "do-advanced-coloring-sub") ;; 2024-01-07
	(format t "planes=~a~%" planes)
	(format t "elm-list=~a~%" elm-list)
	(format t "\(print-check\)=~a~%" (print-check))
	(finish-output)
	)
      (when (print-check)
	(let (cells cell row col cand num kind)
          ;;(print-depth)
          (format t "Advanced Coloringにより")
          (cond
            ((>= (color-mode) 1)
             (print-colored-string '*elimination-color*
                               (format nil "[~a]" (short-color-name '*elimination-color*))))
            (t (format t "[~a]" (short-color-name '*elimination-color*))))
          (format t "の位置から候補を削除できます。~%")
          ;; [elm-list] ::= ([elm-cand]...) ;
          ;; [elm-cand] ::= ([セル・アドレス] ([削除種類] ([number]))) ;
          ;; [削除種類] ::= cannotbe | mustbe ;
          (dolist (elm elm-list)
            (setf cell (first elm) row (first cell) col (second cell))
            (setf kind (first (second elm)))
            (setf num (second (second elm)))
            (if (and (identity num) (atom num)) (setf num (list num)))
            (setf cand (aref brd row col))
            (setf (aref elm-brd row col) *at-mark*)
            (cond
              ((equal kind 'cannotbe)
               (dolist (p num)
		 (setf color-brd (set-colored-candidate color-brd cell p '*elimination-color*))))
              ((equal kind 'mustbe)
               (setf num (first num))
               ;; 確定値となる候補を緑で彩色する。
               (setf color-brd (set-colored-candidate color-brd cell num 'green))
               ;; 確定値となる候補と同一セル内の他の候補数字を赤で彩色する。
               (dolist (p (set-difference cand (list num) :test #'equal))
		 (setf color-brd (set-colored-candidate color-brd cell p '*elimination-color*))
		 )
               ;; 確定値となるセルのハウス内に存在する,確定値と同じ値の候補数字を赤で彩色する。
               (setf cells (set-difference (same-house-cells cell) (list cell) :test #'equal))
               (dolist (cell cells)
		 (setf cand (aref brd (first cell) (second cell)))
		 (when (and (pure-listp cand) (member num cand))
                   (setf color-brd (set-colored-candidate color-brd cell num '*elimination-color*))
                   )
		 )
               )
              )
            )
          ;;(print-mini elm-brd)
          (cond
            ((show-color-board)
             (print-normal color-brd))
            (t (print-mini elm-brd)))
          )
	) ;; end when
      (setf brd (do-elimination brd elm-list))
      (setf brd (clean-up-board brd))
      (copy-board brd elm-brd)
      ) ;; end loop
    (return-from do-advanced-coloring-sub (values brd info-list-list))
    ) ;; end let
  ) ;; end do-advanced-coloring-sub

(defun do-coloring (board)
"指定された盤面[board]に対してAdvanced Coloringによる彩色を行う。
各候補数字ごとに彩色を行い、ある候補数字に対して複数のクラスタが存在する場合は
複数のクラスタをひとつのリストにまとめた上で[planes]の[1]から[*board-size*]に
結果を登録して返す。"
  (let (complete-graph subgraph brd colored-board planes connected-groups plane-elements)
    (when (debug-write-p "do-coloring")
      (format t "(do-coloring~%")
      (print-normal board)
      (format t ")~%")
      ) ;; end when
    (setf planes (make-array (1+ *board-size*) :initial-element nil)) ;; use 1...*board-size*
    (setf brd (new-board board))
    (setf complete-graph (make-graph))
    (setf complete-graph (find-bilocation brd complete-graph))
    (setf complete-graph (mark-bivalue-cell brd complete-graph))
    ;; 完全グラフ[complete-graph]のすべてのリンクラベルを得る。
    (let (adj-list)
      (setf plane-elements nil)
      (dotimes (i *board-size*)
        (dotimes (j *board-size*)
          (when (typep (aref complete-graph i j) 'vertex)
            (setf adj-list (vertex-adj-list (aref complete-graph i j)))
            (dolist (adj adj-list)
              (setf plane-elements (union (get-labels adj) plane-elements))))))
      (when (pure-listp plane-elements)
        (setf plane-elements (sort (copy-seq plane-elements) #'<)) ) )
    (let (new-elements new-elt start-cell cell-elt cells cells-added bivalue-cells color-info cluster)
      (dolist (candidate plane-elements)
        ;; 候補数字[candidate]のstrong linkからなるグラフを作成する。
        (debug-write "do-coloring" (format nil "~%*** candidate = ~d~%" candidate))
        (setf subgraph (make-graph))
        (setf subgraph (find-conjugate-pair-for brd subgraph candidate))
        (setf subgraph (mark-bivalue-cell brd subgraph))
        (setf subgraph (setup-graph-unseen subgraph))
        (setf connected-groups (get-connected-group subgraph))
        ;; それぞれの連結部分木(クラスタ)に対してクラスタ拡張を行う。
        (dolist (cgroup connected-groups)
          (debug-write "do-coloring" (format nil "cgroup = ~s~%" cgroup))
          (setf cluster (copy-seq cgroup))
          ;; クラスタ内の2値セルのリストと2値セルに含まれる要素(候補数字)の和集合を得る。
          (multiple-value-setq (new-elements bivalue-cells)
            (get-bivalue-elements subgraph cluster))
          ;; クラスタ拡張の候補となるのは現在対象としている候補数字以外。
          (setf new-elements (set-difference new-elements (list candidate) :test #'=))
          (if (null new-elements) (return))
          (setf new-elements (sort (copy-seq new-elements) #'<))
            (when (debug-write-p "do-coloring-2")
              (format t "  bivalue-cells = ~a~%" bivalue-cells)
              (format t "  new-elements = ~a~%" new-elements) )
          ;; 初期状態のクラスタに対する彩色を行う。
          (setf start-cell (first cluster))
          (debug-write "do-coloring-1" (format nil "start-cell = ~a~%" start-cell))
          (setf colored-board (do-coloring-board brd subgraph start-cell))
          ;; 連結部分木に対してクラスタ拡張を行う。
          (debug-write "do-coloring" (format nil "@@連結部分木に対してクラスタ拡張を行います。~%"))
          (loop
            (when (debug-write-p "do-coloring-3")
              (format t "  bivalue-cells = ~a~%" bivalue-cells)
              (format t "  new-elements = ~a~%" new-elements) )
            (if (null bivalue-cells) (return)) ;; exit this loop.
            ;; 連結部分木のメンバーである2値セルからクラスタを拡張する。
            (setf cells-added nil)
            (dolist (p-cell bivalue-cells)
              ;; クラスタ拡張の対象となる2値セルから候補数字を得る。
              (setf cell-elt (aref brd (first p-cell) (second p-cell)))
              (setf color-info (aref colored-board (first p-cell) (second p-cell)))
              (setf new-elt (first (intersection new-elements cell-elt)))
              (debug-write "do-coloring-4" (format nil "new-elt = ~d~%" new-elt) )
              (when (identity new-elt) ;; クラスタ拡張を行う。
                ;; [p-cell]と接続しているbilocation cellを得る。
                (multiple-value-setq (subgraph cells)
                  (find-conjugate-pair-for brd subgraph new-elt (list p-cell)))
                (setf cells (set-difference cells (list p-cell) :test #'equal))
                (setf cells (sort (copy-seq cells) #'cell-order-p)) ;; 2024-01-07
                (debug-write "do-coloring-5" (format nil "cells=~a~%cells-added=~a" cells cells-added))
                (setf cells-added (union (copy-seq cells) cells-added :test #'equal))
                (setf cells-added (sort (copy-seq cells-added) #'cell-order-p))
                (debug-write "do-coloring-6.1" (format nil "sorted cells-added=~a" cells-added))
                (debug-write "do-coloring-6.1" (format nil "cluster=~a" cluster))
                ;;(setf tmp (copy-seq cells-added))
                (setf cluster (union (copy-seq cells-added) cluster :test #'equal))
                (setf cluster (sort (copy-seq cluster) #'cell-order-p))
                (debug-write "do-coloring-6.2" (format nil "sorted cells-added=~a" cells-added))
                ;; [p-cell]の彩色情報を基に[p-cell]と接続しているbilocation cellを彩色する。
                (dolist (p cells)
                  (setf colored-board
                        (coloring-cell colored-board p-cell color-info (list new-elt) p)) ) )
              ) ;; end dolist
            (if (null cells-added) (return)) ;; exit this loop.
            (when (identity cells-added)
              (multiple-value-setq (new-elements bivalue-cells)
                (get-bivalue-elements subgraph cells-added))
              (setf bivalue-cells (set-difference bivalue-cells cells-added :test #'equal)) )
            ) ;; end loop
          (push colored-board (aref planes candidate))
          (when (debug-write-p "do-coloring")
            (format t "@@@ After expanding cluster: candidate = ~a~%" candidate)
            (print-normal colored-board)
            )
          )
        )
      )
    (when (debug-write-p "output-graphviz-data")
      (output-graphviz-data subgraph)
      (force-output))
    (when (debug-write-p "do-coloring-planes")
      (let (p len)
        (dotimes (i *board-size*)
          (setf p (aref planes (1+ i)))
          (when (identity p)
            (setf len (length p))
            (dotimes (j len)
              (format t "@@@ candidate ~d cluster ~d~%" (1+ i) j)
              (print-normal (nth j p)) )))))
    (return-from do-coloring planes)))

(defun do-coloring-board (colored-brd graph start-cell)
"連結部分木[graph]による塗り分けを指定されたセル[start-cell]から開始する。
親セルの塗り分け情報と親セルからのリンク・ラベルを基に現在のセルの塗り分けを行う。"
  (let (gr parents-path parents-cell current-cell unseen-cell link-label color-info c-brd)
    (when (debug-write-p "do-coloring-board")
      (format t "(do-coloring-board ~%")
      (print-normal colored-brd)
      ;;(format t "~s~%" graph)
      (format t "[graph] ")
      (format t "~s)~%" start-cell)
      )
    ;; 初期設定。
    (setf c-brd (new-board colored-brd))
    (setf gr (new-graph graph))
    (setf current-cell start-cell)
    (setf parents-cell nil)
    (setf parents-path nil)
    (push nil parents-path)
    ;; 親セルのカラー情報と親セルからのリンク情報を元に
    ;; 深さ優先で連結部分木をたどりながら塗り分けを行う。
    (loop
      (if (null parents-path) (return))
      (loop
        (if (null current-cell) (return))
        (push current-cell parents-path)
        (cond
          ((null parents-cell)
           (setf unseen-cell  (get-unseen-cell gr current-cell))
           (setf link-label (get-labels (adj-info gr start-cell unseen-cell)))
           (setf color-info nil))
          ((identity parents-cell)
           (setf link-label (get-labels (adj-info gr parents-cell current-cell)))
           ;; 隣接セルへのリンク・ラベルが自身のセル内で彩色されていない場合は彩色しておく。
           (setf c-brd (add-color c-brd parents-cell link-label))
           (setf color-info (get-colors c-brd parents-cell)) ))
        (when (debug-write-p "do-coloring-board")
          (format t "(coloring-cell [c-brd] ~s ~s ~s ~s)~%"
                  parents-cell color-info link-label current-cell)
          )
        (setf c-brd (coloring-cell c-brd parents-cell color-info link-label current-cell))
        ;; 未訪問セルを持つ親セルまでバックトラックする。
        (loop
          (setf unseen-cell (pop-unseen-cell gr current-cell))
          (cond
            ((identity unseen-cell)
             (setf parents-cell current-cell)
             (setf current-cell unseen-cell)
             (return))
            ((null parents-path)
             (return-from do-coloring-board c-brd)))
          (setf current-cell (pop parents-path))
          (cond
            ((null current-cell) (return))
            (t (setf parents-cell (first parents-path))))
          ) ;;end loop
        )   ;;end loop
      (setf current-cell (pop parents-path))
      ) ;;end loop

    (when (debug-write-p "do-coloring-board")
      (format t "do-coloring-board : c-brd=~a~%" c-brd)
      (finish-output)
      )

    (return-from do-coloring-board c-brd)
    ) ;; end let
  ) ;; end do-coloring-board

(defun analyze-cluster (planes)
"彩色結果一覧を受け取って削除・特定できる候補がないか解析する。
結果として削除・特定できる候補のリストを返す。返されるリストの形式は
[削除可能データリスト] ::= (([セル・アドレス] ([削除種類] [削除可能候補]))...) | nil ;
[削除種類] ::= cannotbe | mustbe ;"
  (let (plane env len brd-lst info-list info-list-list elm-list)
    (reset-elimination-list)
    (setq info-list nil)
    (setq info-list-list nil)
    (do ((i 1 (1+ i)))
        ((> i *board-size*))
      (setf brd-lst (aref planes i))
      ;;(format t "analyze-cluster:(aref planes ~d) = ~s~%" i brd-lst)
      (setf len (length brd-lst))
      (dotimes (j len)
        (setf env (list i j)) ;; i = plane, j = cluster
        (setf plane (nth j brd-lst))
        ;;(if (identity plane) (add-elimination-list (analyze-cluster-kernel plane env)))))
        (when (identity plane)
	  (multiple-value-setq (elm-list info-list) (analyze-cluster-kernel plane env))
	  (when (and info-list elm-list)
	    (push info-list info-list-list)
	    (add-elimination-list elm-list)
	    ) ;; end when
	  ) ;; end when
	) ;; end dotimes
      ) ;; end do
    ;;(format t "analyze-cluster returns ~a~%" (add-elimination-list))
    (return-from analyze-cluster (values (add-elimination-list) info-list-list))
    ) ;; end let
  ) ;; end analyze-cluster

(defun analyze-cluster-kernel (colored-board env) ;; [env] ::= ([plane] [cluster]) ;
"候補数字[candidate]に対する彩色済みボード[colored-board]を受け取って削除・特定できる
候補がないか解析する。削除・特定できる候補が存在したときは[削除可能データ]のリストを返す。

(rule\#1) ひとつのセル内の2つの異なる候補数字が同じ色で塗り分けられている。
(rule\#2) 同じグループ(ユニット)に属する同じ数字に対する2つの候補数字が同じ色に彩色されている。
(rule\#3) 未確定の値を持つセル内に2つの異なる色が存在する。
(rule\#4) ある数字に対して複数の候補数字が存在するグループで、その数字に対して異なる色で彩色
    された色が2つある。
(rule\#5) 彩色されている数字のグループに属すセルであって、そのセルのグループに「反対の色」で彩色
    された同じ値の候補数字が存在する。
(rule\#6) 彩色されていない候補数字と同じグループ内に同じ値の彩色された候補数字(a)が存在し、
    彩色されていない候補数字と同じセルに(a)と反対の色に彩色された候補数字が存在する。

(rule\#1),(rule\#2) = 矛盾が発生している色に彩色されている候補数字すべてを削除できる。
(rule\#3),(rule\#4) = 塗り分けられていない候補数字を削除できる。
(rule\#5),(rule\#6) = 該当する候補数字を削除できる。"

  (let (lst only-enough row col c-brd info-list)

    (if (null colored-board)
	(return-from analyze-cluster-kernel (add-elimination-list))
	) ;; end if
    (setf c-brd (new-board colored-board))
    (setf only-enough nil)
    (setq info-list nil)

    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (when (and (not only-enough) (setf lst (analyze-rule-1 c-brd i j env)))
          (setf only-enough t)
          (add-elimination-list lst)
	  (when (identity lst)
	    (record-quiz-info :function-name 'do-advanced-coloring)
	    (record-quiz-info :explanation (format nil "<rule\#1> ~dに対するAdvanced Coloring" (first env)))
	    (record-quiz-info :position c-brd)
	    (record-quiz-info :candidate (convert-to-normal-elimination-format lst))
	    (push (record-quiz-info) info-list)
	    (reset-record-quiz-info)
	    ) ;; end when
	  ) ;; end when
        (when (setf lst (analyze-rule-3 c-brd i j env))
          (add-elimination-list lst)
	  (when (identity lst)
	    (record-quiz-info :function-name 'do-advanced-coloring)
	    (record-quiz-info :explanation (format nil "<rule\#3> ~dに対するAdvanced Coloring" (first env)))
	    (record-quiz-info :position c-brd)
	    (record-quiz-info :candidate (convert-to-normal-elimination-format lst))
	    (push (record-quiz-info) info-list)
	    (reset-record-quiz-info)
	    ) ;; end when
	  ) ;; end when
        (when (setf lst (analyze-rule-5 c-brd i j env))
          (add-elimination-list lst)
	  (when (debug-write-p "analyze-cluster-kernel")
	    (format t "rule\#5 c-brd=~%")
	    (print-normal c-brd)
	    (format t "lst=~a, env=~a~%" lst env)
	    )
	  (when (identity lst)
	    (record-quiz-info :function-name 'do-advanced-coloring)
	    (record-quiz-info :explanation (format nil "<rule\#5> ~dに対するAdvanced Coloring" (first env)))
	    (record-quiz-info :position c-brd)
	    (record-quiz-info :candidate (convert-to-normal-elimination-format lst))
	    (push (record-quiz-info) info-list)
	    (reset-record-quiz-info)
	    ) ;; end when
	  ) ;; end when
        (when (setf lst (analyze-rule-6 c-brd i j env))
          (add-elimination-list lst)
	  (when (identity lst)
	    (record-quiz-info :function-name 'do-advanced-coloring)
	    (record-quiz-info :explanation (format nil "<rule\#6> ~dに対するAdvanced Coloring" (first env)))
	    (record-quiz-info :position c-brd)
	    (record-quiz-info :candidate (convert-to-normal-elimination-format lst))
	    (push (record-quiz-info) info-list)
	    (reset-record-quiz-info)
	    ) ;; end when
	  ) ;; end when
        ) ;; end dotimes
      ) ;; end dotimes
    (setf only-enough nil)
    (dolist (kind (list 'block 'row 'col))
      (dotimes (i *board-size*)
        (cond
          ((equal kind 'block)
           (setf row (block-base-row i) col (block-base-col i))
	   )
          ((equal kind 'row)
           (setf row i col 0)
	   )
          ((equal kind 'col)
           (setf row 0 col i))
	  ) ;; end cond
        (when (and (not only-enough) (setf lst (analyze-rule-2 c-brd row col env)))
          (setf only-enough t)
          (add-elimination-list lst)
	  (when (identity lst)
	    (record-quiz-info :function-name 'do-advanced-coloring)
	    (record-quiz-info :explanation (format nil "<rule\#2> ~dに対するAdvanced Coloring" (first env)))
	    (record-quiz-info :position c-brd)
	    (record-quiz-info :candidate (convert-to-normal-elimination-format lst))
	    (push (record-quiz-info) info-list)
	    (reset-record-quiz-info)
	    ) ;; end when
	  ) ;; end when
        (when (setf lst (analyze-rule-4 c-brd row col env))
          (add-elimination-list lst)
	  (when (identity lst)
	    (record-quiz-info :function-name 'do-advanced-coloring)
	    (record-quiz-info :explanation (format nil "<rule\#4> ~dに対するAdvanced Coloring" (first env)))
	    (record-quiz-info :position c-brd)
	    (record-quiz-info :candidate (convert-to-normal-elimination-format lst))
	    (push (record-quiz-info) info-list)
	    (reset-record-quiz-info)
	    ) ;; end when
	  ) ;; end when
        ) ;; end dotimes
      ) ;; end dolist
    (return-from analyze-cluster-kernel (values (add-elimination-list) info-list))
    ) ;; end let
  ) ;; end analyze-cluster-kernel

(defun convert-to-normal-elimination-format (elm-list)
"引数が[elimination-list]の定義を満たすか否かを調べ、満たしていれば正規化した削除・確定フォーマット
に変換したリストを返す。そうでなければ[nil]を返す。

ex. ((3 8) (cannotbe 2)) ==> ((cannotbe (3 8) (2)))

[elimination-list] ::= ( [elimination-element]+ ) | nil ;
[elimination-element] ::= ( [cell-address] ([kind] {[candidate]|([candidate]+)}) ) ;
[cell-address] ::= ([row] [col]) ;
[kind] ::= 'cannotbe | 'mustbe ;
[candidate] ::= {1...[*board-size*]} ;
[*board-size*] ::= 9x9のナンプレであれば「9」 ;
"
  (cond
    ((null elm-list)
     nil
     )
    ((symbolp elm-list)
     nil
     )
    ((simple-regacy-elimination-format-p elm-list)
     (cond
       ((integerp (second (second elm-list)))
	(list (list (first (second elm-list)) (first elm-list) (list (second (second elm-list)))))
	)
       ((pure-listp (second (second elm-list)))
	(list (list (first (second elm-list)) (first elm-list) (second (second elm-list))))
	)
       ) ;; cond
     )
    ((regacy-elimination-format-p elm-list)
     (mapcan #'convert-to-normal-elimination-format elm-list)
     )
    (t
     nil
     )
    ) ;; end cond
  ) ;; end convert-to-normal-elimination-format

(defun regacy-elimination-format-p (elm)
  (cond
    ((null elm)
     nil
     )
    ((symbolp elm)
     nil
     )
    ((simple-regacy-elimination-format-p elm)
     t
     )
    ((simple-regacy-elimination-format-p (first elm)) ;; [elimination-list] ?
     (cond
       ((null (rest elm))
	t
	)
       (t
	(regacy-elimination-format-p (rest elm))
	)
       ) ;; end cond
     )
    (t
     nil
     )
    ) ;; end cond
  ) ;; end regacy-elimination-format-p

(defun simple-regacy-elimination-format-p (elm)
  "[guess-game]実装以前の内部形式の削除・確定データ形式なら[t]、そうでないなら[nil]を返す。"
  (cond
    ((symbolp elm)
     nil
     )
    ((and ;; [elimination-element] ?
      (pure-listp elm)
      (= (length elm) 2)
      (cell-addr-p (first elm) 'internal)
      (pure-listp (second elm))
      (member (first (second elm)) '(cannotbe mustbe) :test #'equal)
      (or
       (integerp (second (second elm)))
       (and
	(pure-listp (second (second elm)))
	(subsetp (second (second elm)) *np-digit* :test #'=)
	)
       )
      )
     ) ;; end ((and...
    )  ;; end cond
  ) ;; end regacy-elimination-format-p

(defun analyze-rule-1 (colored-board row col env)
"(1) ひとつのセル内の2つの異なる候補数字が同じ色で塗り分けられている。
 ==> 矛盾が発生している色に彩色されている候補数字すべてを削除できる。

[candidate] ::= ( {[candidate] | ([colored-candidate]} ... )
[colored-candidate] ::= ([color-name] [candidate])
[candidate] ::= [number]
[color-name] ::= [atom]
[env] ::= ([plane number] [cluster number])"
  (let (colored-candidates elm-list color-1 color-2 color-name
                           info-list candidate color-1-candidates color-2-candidates)
    (if (null colored-board) (return-from analyze-rule-1 nil))
    ;; 初期設定。
    (setf elm-list nil color-1 0 color-2 0)
    (setf color-1-candidates nil color-2-candidates nil)
    (setf colored-candidates (get-colors colored-board (list row col)))

    ;; それぞれの色が使用されている回数を得る。
    (loop
       (if (null colored-candidates) (return))
       (setf candidate (pop colored-candidates))
       (setf color-name (first candidate))
       (cond
         ((equal color-name (first *parity-colors*))
          (push (second candidate) color-1-candidates)
          (incf color-1))
         ((equal color-name (second *parity-colors*))
          (push (second candidate) color-2-candidates)
          (incf color-2))
         ((equal color-name *conflict-color*)
          (error "analyze-rule-1: invalid color name ~s." color-name))))

    ;; 同じ色が複数回使用されている場合は、その色に彩色されている候補数字を削除可能データ
    ;; として[elm-list]に記録する。
    (cond
      ((and (>= color-1 2) (>= color-2 2))
       (error "analyze-rule-1: can't happen. Too many conflict."))
      ((>= color-1 2)
       (setf info-list (delete-colored-candidates-for (first *parity-colors*) colored-board))
       (setf elm-list (make-cannotbe-list info-list)))
      ((>= color-2 2)
       (setf info-list (delete-colored-candidates-for (second *parity-colors*) colored-board))
       (setf elm-list (make-cannotbe-list info-list)))
      (t (do-nothing)))

    (when (and (identity elm-list) (not (subsetp elm-list (add-elimination-list) :test #'equal)))
      (plot-info "Advanced Coloring(r#1)" *difficulty-advanced-coloring* 22)
      (method-applied 'do-advanced-coloring)
      (when (>= (explanation-level) 10)
        (format t "coloring for ~d, cluster \#~d~%" (first env) (second env))
        ;;(cond
        ;;  ((identity (print-eliminatable))
        ;;   (print-elimination-board colored-board elm-list))
        ;;  (t (print-normal colored-board)))
        (print-normal colored-board)
        )
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (print-analyze-rule-number 1)
        (cond
          ((>= color-1 2)
           (setf color-name (first *parity-colors*))
           (format t "[~a]の候補数字~sはすべて"
                   (cell-addr (list row col)) (sort (copy-seq color-1-candidates) #'<))
           (cond
             ((>= (color-mode) 1)
              (print-colored-string color-name (format nil "(~c)" (short-color-name color-name))))
             (t (format t "(~c)" (short-color-name color-name))))
           (format t "で彩色されています。"))
          ((>= color-2 2)
           (setf color-name (second *parity-colors*))
           (format t "[~a]の候補数字~sはすべて"
                   (cell-addr (list row col)) (sort (copy-seq color-2-candidates) #'<))
           (cond
             ((>= (color-mode) 1)
              (print-colored-string color-name (format nil "(~c)" (short-color-name color-name))))
             (t (format t "(~c)" (short-color-name color-name))))
           (format t "で彩色されています。")))
        (format t "すべての")
        (cond
          ((>= (color-mode) 1)
           (print-colored-string color-name (format nil "(~c)" (short-color-name color-name))))
          (t (format t "(~c)" (short-color-name color-name))))
        (format t "を削除できます。")
        (format t "~%  ==> ")
        (print-elimination-list elm-list)
        (terpri)
        )
      )
    (return-from analyze-rule-1 elm-list)))

(defun analyze-rule-2 (colored-board i j env)
"(2) 同じグループ(ユニット)に属する同じ数字に対する2つ以上の候補数字が同じ色に彩色されている。
 ==> 矛盾なので同じ色に彩色されている候補数字すべてを削除できる。"
  (let (cells candidates elm-list contradiction-color contradiction-candidate
              cell-0 info-list elm-flag)
    (if (null colored-board) (return-from analyze-rule-2 nil))
    (setf elm-flag nil elm-list nil)
    (dolist (kind (list 'block 'row 'col))
      ;; 指定されたセルを含むユニット内のすべてのセル・アドレスのリストを返す。
      (cond
        ((equal kind 'block)
         (setf cells (same-block-cells (list i j))))
        ((equal kind 'row)
         (setf cells (same-row-cells (list i j))))
        ((equal kind 'col)
         (setf cells (same-col-cells (list i j)))))

      ;; 指定されたセルを含むユニット内のすべての彩色済み候補数字を得る。
      (setf candidates nil)
      (dolist (cell cells)
        ;;(push (get-colors colored-board cell) candidates))
        (setf candidates (append (get-colors colored-board cell) candidates)))

      ;; 彩色済み候補数字を数字順、数字が同じ時は色名順に並べたリストを得る。
      (setf candidates (sort (copy-seq candidates) #'color-order-p))

      ;; [candidates]の先頭2つの要素を比較して同じであれば重複。
      (setf elm-list nil contradiction-color nil)
      (loop
         (if (null candidates) (return))
         (setf cell-0 (pop candidates))
         (when (equal cell-0 (first candidates))
           (setf contradiction-color (first cell-0))
           (setf contradiction-candidate (second cell-0))
           (return)))

      (when (identity contradiction-color)
        (setf info-list (delete-colored-candidates-for contradiction-color colored-board))
        (setf elm-list (make-cannotbe-list info-list)))

      (when (and (identity elm-list) (not (subsetp elm-list (add-elimination-list) :test #'equal)))
        (plot-info "Advanced Coloring(r#2)" (+ *difficulty-advanced-coloring* 3) 22)
        (method-applied 'do-advanced-coloring)
        (when (and (>= (explanation-level) 10) (null elm-flag))
          (setf elm-flag t)
          (format t "coloring for ~d, cluster \#~d~%" (first env) (second env))
          ;;(cond
          ;;  ((print-eliminatable)
          ;;   (print-elimination-board colored-board elm-list))
          ;;  (t (print-normal colored-board)))
          (print-normal colored-board)
          )
        (when (>= (mod (explanation-level) 10) 1)
          (let (short-name)
            ;;(print-depth)
            (print-analyze-rule-number 2)
            ;;(setf short-name (short-color-name '*elimination-color*))
            (setf short-name (short-color-name contradiction-color))
            (cond
              ((equal kind 'block)
               ;;(format t "contradiction-color = ~s~%" contradiction-color)
               (format t "ブロック(~a)に同じ色" (1+ (block-num i j)))
               (cond
                 ((>= (color-mode) 1)
                  (print-colored-string contradiction-color (format nil "(~a)" short-name)))
                 ;;(print-colored-string '*elimination-color* (format nil "~(a)" short-name)))
                 (t (format t "(~a)" short-name)))
               (format t "で彩色されている複数の(~d)が存在します。" contradiction-candidate)
               )
              ((equal kind 'row)
               ;;(print-depth)
               (format t "行(~a)に同じ色" (1+ i))
               (cond
                 ((>= (color-mode) 1)
                  (print-colored-string contradiction-color (format nil "(~a)" short-name)))
                 ;;(print-colored-string '*elimination-color* (format nil "(~a)" short-name)))
                 (t (format t "(~a)" short-name)))
               (format t "で彩色されている複数の(~d)が存在します。" contradiction-candidate)
               )
              ((equal kind 'col)
               (format t "列(~a)に同じ色" (1+ j))
               (cond
                 ((>= (color-mode) 1)
                  (print-colored-string contradiction-color (format nil "(~a)" short-name)))
                 ;;(print-colored-string '*elimination-color* (format nil "(~a)" short-name)))
                 (t (format t "(~a)" short-name)))
               (format t "で彩色されている複数の(~d)が存在します。" contradiction-candidate)
               )
              )
            (format t "すべての")
            (cond
              ((>= (color-mode) 1)
               (print-colored-string contradiction-color (format nil "(~a)" short-name)))
              ;;(print-colored-string '*elimination-color* (format nil "(~a)" short-name)))
              (t (format t "(~a)" short-name)))
            (format t "を削除できます。")
            (format t "~%  ==> ")
            (print-elimination-list elm-list)
            (terpri)
            )
          ) ;;end when
        (return-from analyze-rule-2 elm-list))
      ) ;; end dolist
    (return-from analyze-rule-2 elm-list)))


(defun analyze-rule-3 (colored-board i j env)
"(3) 未確定の値を持つセル内に2つの異なる色が存在する。
 ==> 塗り分けられていない候補数字を削除できる。"
  (let (candidates colored-candidates elm-list elm-cand)
    (if (null colored-board) (return-from analyze-rule-3 nil))
    (setf elm-list nil elm-cand nil)
    (setf candidates (aref colored-board i j))
    ;; 指定されたセル[cell]に含まれるパリティ・カラーを持つ候補数字をパリティ・カラーと共に返す。
    ;; example: (2 (green 3) 5 (blue 7) 8 9) ==> ((green 3) (blue 7))
    (setf colored-candidates (get-colors colored-board (list i j)))

    (cond
      ((or (null candidates) (integerp candidates)) nil)
      ((< (length candidates) 3) nil)
      ((< (length colored-candidates) 2) nil)
      ((> (length colored-candidates) 2) nil)
      ((not (equal (first (first colored-candidates)) (first (second colored-candidates))))
       (setf elm-cand (set-difference candidates colored-candidates))
       (dolist (k elm-cand)
         (push (list (list i j) k) elm-list))
       (setf elm-list (make-cannotbe-list elm-list)) )
      (t nil))

    (when (and (identity elm-list) (not (subsetp elm-list (add-elimination-list) :test #'equal)))
      (plot-info "Advanced Coloring(r#3)" *difficulty-advanced-coloring* 22)
      (method-applied 'do-advanced-coloring)
      (when (>= (explanation-level) 10)
        (format t "coloring for ~d, cluster \#~d~%" (first env) (second env))
        (cond
          ((print-eliminatable)
           (print-elimination-board colored-board elm-list))
          (t (print-normal colored-board)))
        )
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (print-analyze-rule-number 3)
        (format t "[~a]は" (cell-addr (list i j)))
        (print-colored-candidate (first colored-candidates))
        (format t "か")
        (print-colored-candidate (second colored-candidates))
        (format t "のいずれかです。")
        (format t "~%  ==> ")
        (print-elimination-list elm-list)
        (terpri)
        ))
    (return-from analyze-rule-3 elm-list)))

(defun analyze-rule-4 (colored-board i j env)
"(4) ある数字に対して複数の候補数字が存在するグループで、その数字に対して異なる色に
    彩色された色が2つある。
 ==> 塗り分けられていない候補数字を削除できる。"
  (let (elm-list info-list cell-list cell-0
                 colored-candidates-with-cell peer-1 peer-2 peer-list num elm-flag)
    (if (null colored-board) (return-from analyze-rule-4 nil))
    (setf elm-list nil)
    (dolist (kind (list 'block 'row 'col))
      ;; 指定されたセルを含むユニット内のすべてのセル・アドレスのリストを返す。
      (cond
        ((equal kind 'block)
         (setf cell-list (same-block-cells (list i j))))
        ((equal kind 'row)
         (setf cell-list (same-row-cells (list i j))))
        ((equal kind 'col)
         (setf cell-list (same-col-cells (list i j)))))

      ;; 指定されたセルを含むユニット内のすべての彩色済み候補数字を得る。
      ;; [colored-candidates-with-cell-list] ::= ([colored-candidates-with-cell]...) ;
      ;; [colored-candidates-with-cell]      ::= ([cell-address] [colored-candidate]) ;
      (setf colored-candidates-with-cell nil)
      (dolist (cell cell-list)
        (dolist (lst (get-colors colored-board cell))
          (push (list cell lst) colored-candidates-with-cell)))

      ;; 彩色済み候補数字を数字順、数字が同じ時は色名順に並べたリストを得る。
      (setf colored-candidates-with-cell
            (sort (copy-seq colored-candidates-with-cell) #'color-order-p-with-addr))

      ;; [colored-candidates-with-cell]の先頭2つの要素を比較して
      ;; 同一の候補数字に対して異なる色に彩色された候補が存在するか調べる。
      (setf peer-list nil)
      (loop
         (if (null colored-candidates-with-cell) (return))
         ;; [peer-i] ::= ([cell-address] [colored-candidate]) ;
         ;; [colored-candidate] ::= ([color-name] [number]) ;
         (setf peer-1 (pop colored-candidates-with-cell))
         (setf peer-2 (first colored-candidates-with-cell))
         (setf cell-0 (second peer-1))
         (when (same-candidate-but-color-p cell-0 (second peer-2))
           (push (list peer-1 peer-2) peer-list)
           )
         ) ;; end loop

      (setf elm-flag nil)
         
      (dolist (peer-cells peer-list)
        (setf peer-1 (first peer-cells) peer-2 (second peer-cells))
        (setf num (second (second peer-1)))
        (setf info-list (delete-non-colored-candidates-for num cell-list colored-board))
        (setf elm-list (make-cannotbe-list info-list))
        (when (and (identity elm-list)
                   (not (subsetp elm-list (add-elimination-list) :test #'equal)))
          (plot-info "Advanced Coloring(r#4)" (+ *difficulty-advanced-coloring* 2) 22)
          (method-applied 'do-advanced-coloring)
          (when (and (null elm-flag) (>= (explanation-level) 10))
            (setf elm-flag t)
            (format t "coloring for ~d, cluster \#~d~%" (first env) (second env))
            (cond
              ((print-eliminatable)
               (print-elimination-board colored-board elm-list))
              (t (print-normal colored-board)))
            )
          (when (>= (mod (explanation-level) 10) 1)
            ;;(print-depth)
            (print-analyze-rule-number 4)
            (cond
              ((equal kind 'block)
               (format t "ブロック(~a)の~dは" (1+ (block-num i j)) num)
               (print-colored-candidate (second peer-1))
               (format t "か")
               (print-colored-candidate (second peer-2))
               (format t "のどちらかです。"))
              ((equal kind 'row)
               (format t "行(~a)の~dは" (1+ i) num)
               (print-colored-candidate (second peer-1))
               (format t "か")
               (print-colored-candidate (second peer-2))
               (format t "のどちらかです。"))
              ((equal kind 'col)
               (format t "列(~a)の~dは" (1+ j) num)
               (print-colored-candidate (second peer-1))
               (format t "か")
               (print-colored-candidate (second peer-2))
               (format t "のどちらかです。")))
            (format t "~%  ==> ")
            (print-elimination-list elm-list)
            (terpri)
            )
          )
        )
      ) ;; end dolist
    (return-from analyze-rule-4 elm-list)))

(defun analyze-rule-5 (colored-board row col env)
"(5) 彩色されている数字のグループに属すセルであって、そのセルのグループに「反対の色」で彩色
    された同じ値の候補数字が存在する。
 ==> 両方の色のセルを同時に見ることができる候補数字を削除できる。"
  (let (elm-list non-colored-candidates colored-candidates-with-cell cell-list cell-0
                 ;;(let (elm-list non-colored-candidates colored-candidates-with-cell cell-list cell-0 cell-1
                 peer-list peer-1 peer-2 candidate)
    (if (null colored-board) (return-from analyze-rule-5 nil))
    ;; 初期設定。
    (setf elm-list nil peer-list nil)

    ;; [row]行[col]列の指定されたセル内の彩色されていない候補数字を得る。
    (setf candidate (aref colored-board row col))
    (if (or (null candidate) (integerp candidate)) (return-from analyze-rule-5 nil))
    (setf non-colored-candidates
          (set-difference candidate (get-colors colored-board (list row col))))

    (when (null non-colored-candidates) (return-from analyze-rule-5 nil))

    ;; ユニット内の彩色済み候補数字を得る。
    (setf cell-list (same-unit-cells (list row col)))

    (setf colored-candidates-with-cell nil)
    ;; [colored-candidates-with-cell]      ::= ([cell-address] [colored-candidate]) ;
    (dolist (cell cell-list)
      (dolist (lst (get-colors colored-board cell))
        (push (list cell lst) colored-candidates-with-cell)))

    ;; 彩色済み候補数字を数字順、数字が同じ時は色名順に並べたリストを得る。
    (setf colored-candidates-with-cell
          (sort (copy-seq colored-candidates-with-cell) #'color-order-p-with-addr))

    ;; 反対の色で彩色された同じ値の候補数字が存在するか調べる。
    (loop
      (if (null colored-candidates-with-cell) (return))
      ;; [peer-i] ::= ([cell-address] [colored-candidate]) ;
      ;; [colored-candidate] ::= ([color-name] [number]) ;
      (setf peer-1 (pop colored-candidates-with-cell))
      (setf peer-2 (first colored-candidates-with-cell))
      (setf cell-0 (second peer-1))
      (when (and
             (same-candidate-but-color-p cell-0 (second peer-2))
             (intersection (list (second cell-0)) non-colored-candidates))
        ;; [peer-list] ::= (([colored-candidate-with-cell] [colored-candidate-with-cell])...)
        (push (list peer-1 peer-2) peer-list)
        (setf elm-list
              (union (make-cannotbe-list (list (list (list row col) (second cell-0))))
                     elm-list :test #'equal))
        ) ;; end when
      )   ;; end loop

    (when (and (identity elm-list) (not (subsetp elm-list (add-elimination-list) :test #'equal)))
      (plot-info "Advanced Coloring(r#5)" (+ *difficulty-advanced-coloring* 5) 22)
      (method-applied 'do-advanced-coloring)
      (when (>= (explanation-level) 10)
        (format t "coloring for ~d, cluster \#~d~%" (first env) (second env))
        (cond
          ((print-eliminatable)
           (print-elimination-board colored-board elm-list))
          (t (print-normal colored-board)))
        )
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (print-analyze-rule-number 5)
        (dolist (peer-cells peer-list)
          ;; [peer-i] ::= ([cell-address] [colored-candidate]) ;
          (setf peer-1 (first peer-cells) peer-2 (second peer-cells))
          ;;(setf cell-1 (first peer-1) candidate (second (second peer-1)))
          (setf candidate (second (second peer-1)))
          (format t "[~a]の" (cell-addr (list row col)))
          (print-colored-candidate (list '*elimination-color* candidate))
          (format t "は[~a]の" (cell-addr (first peer-1)))
          (print-colored-candidate (second peer-1))
          (format t "と[~a]の" (cell-addr (first peer-2)))
          (print-colored-candidate (second peer-2))
          (format t "を同時に見ることができる位置です。")
          (format t "~%  ==> ")
          (print-elimination-list elm-list)
          (terpri)
          )
        )
      )
    (debug-write "analyze-rule-5" (format nil "elm-list=~a~%" elm-list))
    (return-from analyze-rule-5 elm-list)
    ) ;; end let
  ) ;; end analyze-rule-5

(defun analyze-rule-6 (colored-board row col env)
"(6) 彩色されていない候補数字と同じグループ内に同じ値の彩色された候補数字(a)が存在し、
    彩色されていない候補数字と同じセルに(a)と反対の色に彩色された候補数字が存在する。
 ==> 彩色されていない候補数字を削除できる。"
  (let (elm-list non-colored-candidates colored-candidates colored-candidate
                 non-colored-candidate colored-candidates-with-cell cell-list color peer-0)
    (if (null colored-board) (return-from analyze-rule-6 nil))
    (setf elm-list nil)
    ;; 指定されたセル内に彩色されたセルがひとつだけ存在していることが必要。
    (setf colored-candidates (get-colors colored-board (list row col)))
    (if (not (= (length colored-candidates) 1)) (return-from analyze-rule-6 elm-list))

    ;; 唯一の彩色済み候補。
    (setf colored-candidate (first colored-candidates))

    ;; セル内の彩色されていない候補数字。
    (setf non-colored-candidates
          (set-difference (aref colored-board row col) colored-candidates :test #'equal))

    ;; ユニット内の彩色済み候補数字全体を得る。
    (setf cell-list (same-unit-cells (list row col)))
    (setf colored-candidates-with-cell nil)
    ;; [colored-candidates-with-cell]      ::= ([cell-address] [colored-candidate]) ;
    (dolist (cell cell-list)
      (dolist (lst (get-colors colored-board cell))
        (push (list cell lst) colored-candidates-with-cell)))
    
    ;; 彩色済み候補数字を数字順、数字が同じ時は色名順に並べたリストを得る。
    (setf colored-candidates-with-cell
          (sort (copy-seq colored-candidates-with-cell) #'color-order-p-with-addr))

    ;; セル内の彩色されていない候補数字と同じ値を持ち、セル内の彩色済み候補数字と反対の
    ;; 色を持つ候補数字がユニット内に存在しないかを調べる。
    (setf color (first colored-candidate)) ;; セル内の彩色済み候補数字の色を[color]とする。
    ;;(setf peer-list nil)
    (loop
       (if (null colored-candidates-with-cell) (return))
       ;; [peer-0] ::= ([cell-address] [colored-candidate]) ;
       ;; [colored-candidate] ::= ([color-name] [number]) ;
       (setf peer-0 (pop colored-candidates-with-cell))
       (when (and (intersection non-colored-candidates (list (second (second peer-0))))
                  (equal color (opposite-color (first (second peer-0)))))
         (setf non-colored-candidate (second (second peer-0)))
         (setf elm-list
               (make-cannotbe-list (list (list (list row col) non-colored-candidate))))
         (return)
         ) ;; end when
       )   ;; end loop

    (when (and (identity elm-list) (not (subsetp elm-list (add-elimination-list) :test #'equal)))
      (plot-info "Advanced Coloring(r#6)" (+ *difficulty-advanced-coloring* 7) 22)
      (method-applied 'do-advanced-coloring)
      (when (>= (explanation-level) 10)
        (format t "coloring for ~d, cluster \#~d~%" (first env) (second env))
        (cond
          ((print-eliminatable)
           (print-elimination-board colored-board elm-list))
          (t (print-normal colored-board)))
        )
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (print-analyze-rule-number 6)
        (format t "[~a]の" (cell-addr (list row col)))
        (print-colored-candidate (list '*elimination-color* non-colored-candidate))
        (format t "は[~a]の" (cell-addr (first peer-0)))
        (print-colored-candidate (second peer-0))
        (format t "と同じグループで、セル内の[~a]の" (cell-addr (list row col)))
        (print-colored-candidate colored-candidate)
        (format t "が反対の色で彩色されています。")
        (format t "~%  ==> ")
        (print-elimination-list elm-list)
        (terpri)
        )
      )
    (return-from analyze-rule-6 elm-list)))

(defun print-analyze-rule-number (num)
  (when (>= (mod (explanation-level) 10) 1)
    (format t "(r\#~d) " num)
    )
  (return-from print-analyze-rule-number num)
  )

(defun make-cannotbe-list (info-list)
"指定された[削除対象データ]を削除可能候補として加工して[削除可能データ]のリストを返す。

[削除対象データ(info-list)] ::= (([セル・アドレス] [number])...) ;
[削除可能データ(elm-list)]  ::= ([セル・アドレス] ([削除種類] [number])) ;
[削除種類] ::= cannotbe | mustbe ;
[表示形式リスト] ::= ([セル・アドレス] \"=\" [削除可能候補]) |
                     ([セル・アドレス] \"<>\" [削除可能候補])"
  (let (elm-list)
    (setf elm-list nil)
    (dolist (cell-info info-list)
      (cond
        ((atom (second cell-info))
         (push (list (first cell-info) (list 'cannotbe (second cell-info))) elm-list))
        ((pure-listp (second cell-info))
         (dolist (p (second cell-info))
           (push (list (first cell-info) (list 'cannotbe p)) elm-list)))))
    (return-from make-cannotbe-list (reverse elm-list))))

(defun make-mustbe-list (info-list)
  (let (elm-list)
    (setf elm-list nil)
    (dolist (cell-info info-list)
      (push (list (first cell-info) (list 'mustbe (second cell-info))) elm-list))
    (return-from make-mustbe-list (reverse elm-list))))

(defun delete-colored-candidates-for (color colored-board)
"彩色済みボード[colored-board]内の[color]に彩色された候補数字を削除可能候補として
記録して[削除対象データ]として返す。

[削除対象データ] ::= (([セル・アドレス] [削除可能候補])...) ;
[削除可能候補] ::= [number] ;"
  (let (info-list candidates)
    (setf info-list nil)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf candidates (aref colored-board i j))
        (when (pure-listp candidates)
          (dolist (k candidates)
            (if (and (colored-candidate-p k) (equal (first k) color))
                (push (list (list i j) (second k)) info-list))))))
    (return-from delete-colored-candidates-for info-list)))

(defun delete-non-colored-candidates-for (num cell-list colored-board)
"指定されたセル・アドレスのリスト[cell-list]内の彩色されていない候補数字[num]
の一覧をセル・アドレスとセットにして[削除対象データ]として返す。

[削除対象データ] ::= (([セル・アドレス] [削除可能候補])...) ;
[削除可能候補] ::= [number] ;"
  (let (candidates info-list)
    (setf info-list nil)
    (dolist (cell cell-list)
      (setf candidates (aref colored-board (first cell) (second cell)))
      (when (pure-listp candidates)
        (dolist (i candidates)
          (if (and (integerp i) (= i num)) (push (list cell i) info-list)))) )
    (return-from delete-non-colored-candidates-for info-list)))

(defun coloring-cell (colored-board parent parents-color-info link-label child)
"[child]で指定するセルを親セル[parent]の彩色情報[color-info]と反対のカラーで彩色する。

色の対応は[link-label]の情報と[parents-color-info]の情報を元に組み立てる。
[link-label]と[child]に共通要素が存在することが条件。そうでなければエラー。
[link-label]の要素数は1または2。[parent]が[nil]の場合は参照しない。それ以外はエラー。
セル[child]への最終的な色情報の書き込みは関数[set-color]が行う。

(P) 親セルの内容 = 彩色済みセル(p1,p2,...)数 + 未彩色セル(q1,q2,...)数。
(C) 子セルの内容 = 彩色済みセル(c1,c2,...)数 + 未彩色セル(d1,d2,...)数。

セル内の彩色済み候補数字(要素)の数は2以下。3以上はバグによるエラー(あってはならない状態)。
(x)は要素 xが持つ色。^(x)は(x)の反対色。(x):yは要素 xと同じ色である候補数字yを示す。

(1) [link-label]の要素がひとつの場合の彩色対象とその結果。(r >= 0, m >= 1, n >= 2)

                  +-------------------------------------------------------------------------+
                  |    c0    |   c1     |     c2      |       c3       |         c4         |
+-----------------+----------+----------+-------------+----------------+--------------------|
|     (P)\(C)     | 1+0 *1   | 0+1 *1   | 0+n         | 1+m            | 2+m                |
+----+------------+----------+----------+-------------+----------------+--------------------|
| p0 | 0+0        | error    | error    | n=1,2のみOK  | c1+^(c1):d1   |          -         |
| p1 | 0+1      *1| error    | error    |     -       |      -         |          -         |
| p2 | 1+0      *1| error    | error    |     -       |      -         |          -         |
| p3 | 1+m(L=p1)  | error    | error    | ^(p1):di    | c1+^(p1):di *3 | (C)が無変化のみ OK  |
| p4 | 1+m(L=qi)*2| error    | error    | ^(qi):di    | c1+^(qi):di *3 | (C)が無変化のみ OK  |
| p5 | 2+0(L=pi)*4| error    | error    | ^(pi):di    | c1+^(pi):di *3 | (C)が無変化のみ OK  |
| p6 | 2+r(L=pi)  | error    | error    | ^(pi):di    | c1+^(p1):di *3 | (C)が無変化のみ OK  |
| p7 | 2+r(L=qi)*5| error    | error    | error       | error          | error              |
+----+------------+----------+----------+-------------+----------------+--------------------+

(2) [link-label]の要素が2つの場合の彩色対象とその結果。(r >= 0, m >= 1, n >= 2)

                    +-------------------------------------------------------------------------+
                    |   C0  |   C1  |        C2         |       C3        |        C4         |
+-------------------+-------+-------+-------------------+-----------------+-------------------|
|      (P)\(C)      | 1+0 *1| 0+1 *1| 0+n               | 1+m             |  2+m              |
+----+--------------+-------+-------+-------------------+-----------------+-------------------|
| P0 | 0+0          | error | error | n=1,2のみOK       | c1+^(c1):di     |          -        |
| P1 | 0+1        *1| error | error | error             | error           | error             |
| P2 | 1+0        *1| error | error | error             | error           | error             |
| P3 | 1+m(p1 ∈ L)*2| error| error | ^(p1):di+^(qj):dj | c1+^(p1):di *3,6| (C)が無変化のみ OK |
| P4 | 1+m(qi ∈ L)  | error| error | error             | error           | error             |
| P5 | 2+0(pi ∈ L)*4| error| error | ^(pi):di+^(pj):dj | c1+^(c1):di *3,6| (C)が無変化のみ OK |
| P6 | 2+m(pi ∈ L)  | error| error | ^(pi):di+^(pj):dj | c1+^(pi):di *3,6| (C)が無変化のみ OK |
| P7 | 2+m(qi ∈ L)*5| error| error | error             | error           | error             |
+----+--------------+-------+-------+-------------------+-----------------+-------------------+

(3) [Link-label]の要素が3つ以上の場合 ==> すべてバグによるエラー(あってはならない状態)。

*1 確定値
*2 (P)側の彩色も必要。
*3 c1の色を変化させる場合はバグによるエラー(あってはならない状態)。
*4 1+1はあり得ない。2値セルなので2+0となっているのが正しい。
*5 ひとつのセル内に存在できる色は2色まで。
*6 (pi)=(c1) ==> c1+^(pi):di
   Ex: (4 7 (blue 9))--(4 9)--((blue 4) 7 9) ==> ((green 4) 7 (blue 9))&((blue 4) 7 (green 9))
*6 (p1)≠(c1) ==> error
   Ex: (4 7 (blue 9))--(4 9)--((green 4) 7 9) ==> ((green 4) 7 (blue 9))&((green 4) 7 (green 9))"
  (let (c-candidates c-numbered-cand c-colored-cand p-candidates p-numbered-cand p-colored-cand)

    (if (null child) (return-from coloring-cell colored-board))

    ;; [c-candidates]   ::= [child]のすべての候補数字のリスト。
    ;; [c-numbered-cand]::= [child]の非彩色候補数字のリスト
    ;; [c-colored-cand] ::= [child]の彩色済み候補数字のリスト
    ;; [c-candidates] = (union [c-numbered-cand] [c-colored-cand])
    (setf c-candidates nil c-numbered-cand nil c-colored-cand nil) ;; 初期設定
    (when (identity child)
      (setf c-candidates (aref colored-board (first child) (second child)))
      (if (or (integerp c-candidates) (colored-candidate-p c-candidates))
          (setf c-candidates (list c-candidates)))
      (setf c-numbered-cand
            (set-difference c-candidates (get-colors colored-board child) :test #'equal))
      ;;(format t "coloring-cell:~a c-numbered-cand=~a~%" (lisp-implementation-type) c-numbered-cand)
      (setf c-colored-cand (set-difference c-candidates c-numbered-cand :test #'equal))
      ;;(format t "coloring-cell:~a c-colored-cand=~a~%" (lisp-implementation-type) c-colored-cand)
      )

    ;; [p-candidates]   ::= [parent]のすべての候補数字のリスト。
    ;; [p-numbered-cand]::= [parent]の非彩色候補数字のリスト
    ;; [p-colored-cand] ::= [parent]の彩色済み候補数字のリスト
    ;; [p-candidates] = (union [p-numbered-cand] [p-colored-cand])
    (setf p-candidates nil p-numbered-cand nil p-colored-cand nil)
    (when (identity parent)
      (let (color num)
        (setf p-candidates (aref colored-board (first parent) (second parent)))
        (if (or (integerp p-candidates) (colored-candidate-p p-candidates))
            (setf p-candidates (list p-candidates)))
        (setf p-numbered-cand (set-difference p-candidates (get-colors colored-board parent)))
        (setf p-colored-cand (set-difference p-candidates p-numbered-cand :test #'equal))
        (when (= (length p-candidates) 2) ;; bivalue cell
          (cond
            ((= (length p-colored-cand) 0)
             (dotimes (i 2)
               (setf color (nth i *parity-colors*))
               (setf num (nth i p-numbered-cand))
               (setf colored-board (set-color colored-board parent num color))))
            ((= (length p-colored-cand) 1)
             (setf color (opposite-color (first (first p-colored-cand))))
             (setf num (first p-numbered-cand))
             (setf colored-board (set-color colored-board parent num color))))
          (setf p-numbered-cand nil)
          (setf p-colored-cand (aref colored-board (first parent) (second parent)))
          )
        )
      )

    ;; 入力データのエラーチェック。表を参照。
    (let (len common)
      (setf common (intersection link-label p-numbered-cand :test #'equal))
      (setf len (length common))
      (cond
        ((and
          (identity parent)
          (null p-candidates))
         (error "空[nil]の彩色情報が許されるのは開始セルだけです。~%") )
        ((not (link-labelp link-label))
         (error "~sは正しい形式のリンク・ラベルではありません。~%" link-label) )
        ((= (length c-candidates) 0)
         (error "子セル[~a]の内容が[nil]です。彩色できません。~%" (cell-addr child)) )
        ((or
          (>= (length c-colored-cand) 3)
          (>= (length p-colored-cand) 3))
         (error "親セルまたは子セルの彩色済み候補数字の数が3つ以上あります。~%") )
        ((= (length link-label) 1)
         (cond
           ((= (length c-candidates) 1)
            (error "子セル[~a]は確定値なので彩色できません。~%" (cell-addr child)) )
           ((and
             (= (length p-colored-cand) 2)
             (>= len 1))
            (error "親セル[~a]の彩色済み候補数字が3つを超えてしまいます。~%" (cell-addr parent)) )
           (t (do-nothing))))
        ((= (length link-label) 2)
         (cond
           ((= (length c-candidates) 1)
            (error "子セル[~a]は確定値なので彩色できません。~%" (cell-addr child)) )
           ((= (length p-candidates) 1)
            (error "親セル[~a]は確定値なので彩色元になれません。~%" (cell-addr parent)) )
           ((and
             (= (length p-candidates) 0)
             (= (length c-candidates) 1))
            (error "親セルが[nil]の場合、子セルの要素は2つ以上必要です。~%") )
           ((and
             (= (length p-colored-cand) 2)
             (>= (length (intersection link-label p-numbered-cand :test #'equal)) 1))
            (error "親セル[~a]の彩色済み候補数字が3つを超えてしまいます。~%" (cell-addr parent)) )))
        (t (do-nothing)))
      )

    ;; 表中のエラー項目は上記のエラー・チェックですべて排除済み(のはず)。
    (let (common c-common n-common color num len candidates)
      ;; [c-common] for common candidates that is colored.
      ;; [n-common] for common candidates that is purely number only.
      (when (debug-write-p "coloring-cell")
        (format t "(parent -> link-label -> child) == (~s -> ~s -> ~s)~%" parent link-label child)
        ;;(format t "Before coloring:~%")
        ;;(print-normal colored-board)
        (force-output))
      (cond
        ((null parents-color-info) ;; 親セルからの彩色情報が空の場合(=p0とP0の行)。
         (setf common (intersection link-label c-candidates :test #'equal))
         (setf len (length common))
         (cond
           ((and (= (length c-colored-cand) 0) (or (= len 1) (= len 2))) ;; [p0 c2] & [P0 C2]
            (dotimes (i (length common))
              (setf colored-board
                    (set-color colored-board child (nth i common) (nth i *parity-colors*)))))
           ((and (= (length c-colored-cand) 1) (= len 1)) ;; [p0 c3] & [P0 C3]
            (setf color (first (first c-colored-cand)))
            (setf colored-board
                  (set-color colored-board child (first common) (opposite-color color))))
           (t (do-nothing)))
         ;;(setf candidates (aref colored-board (first child) (second child)))
         ;;(setf (aref colored-board (first child) (second child)) candidates)
         )
        ((= (length link-label) 1) ;; [link-label]の要素数が1の場合。
         (setf c-common (intersection p-colored-cand link-label :test #'same-candidate-p))
         (setf n-common (intersection link-label p-numbered-cand :test #'equal))
         (cond
           ((and ;; p3, p5, p6の行の処理。
             (identity c-common)
             (null n-common))
            (dolist (candidate c-common)
              ;;(format t "candidate = ~s~%" candidate)
              (setf color (first candidate))
              (setf num (second candidate))
              (setf colored-board (set-color colored-board child num (opposite-color color)))))
           ((and ;; p4の行の処理。
             (= (length p-colored-cand) 1)
             (= (length c-common) 0)
             (= (length n-common) 1))
            (cond
              ((<= (length c-colored-cand) 1) ;; [p4 c2] & [p4 c3]
               (setf color (first (first p-colored-cand)))
               (setf num (first p-numbered-cand))
               (setf colored-board (set-color colored-board parent num (opposite-color color)))
               (setf colored-board (set-color colored-board child num color)))
              (t (do-nothing))))
           (t (do-nothing)))
         ;;(setf candidates (aref colored-board (first child) (second child)))
         ;;(setf (aref colored-board (first child) (second child)) candidates)
         )
        ((= (length link-label) 2) ;; [link-label]の要素数が2の場合。
         (setf c-common (intersection p-colored-cand link-label :test #'same-candidate-p))
         (setf n-common (intersection link-label p-numbered-cand :test #'equal))
         (cond
           ((and ;; P5, P6の行の処理。
             (identity c-common)
             (null n-common))
            (dolist (candidate c-common)
              (setf color (first candidate))
              (setf num (second candidate))
              (setf colored-board (set-color colored-board child num (opposite-color color)))))
           ((and ;; P3の行の処理。
             (= (length p-colored-cand) 1)
             (= (length c-common) 1)
             (= (length n-common) 1))
            ;;(format t "P3の行の処理。~%")
            (setf color (first (first c-common)))
            (setf num (first (intersection link-label n-common :test #'=)))
            (setf colored-board (set-color colored-board parent num (opposite-color color)))
            (setf parents-color-info (get-colors colored-board parent))
            (dolist (candidate parents-color-info)
              (setf color (first candidate))
              (setf num (second candidate))
              (setf colored-board (set-color colored-board child num (opposite-color color))))))
         ;;(setf candidates (aref colored-board (first child) (second child)))
         ;;(setf (aref colored-board (first child) (second child)) candidates)
         )
        (t (error "can not happen at coloring-cell.")))
      (setf candidates (aref colored-board (first child) (second child)))
      (setf candidates (sort (colors-if-bivalue-cell candidates) #'colored-lessp))
      (setf (aref colored-board (first child) (second child)) candidates)
      (when (debug-write-p "coloring-cell")
        (format t "After coloring:~%")
        (print-normal colored-board)
        (force-output))
      )
    (return-from coloring-cell colored-board)))

(defun colors-if-bivalue-cell (candidates)
"bivalue cellであり、かつ一方の候補数字だけが彩色されている場合は残りの
候補数字を彩色されている色と反対の色で彩色したリストを返す。
      7 ==> 7
     (green 2) ==> 2
     ((bule 3) 7) ==> ((blue 3) (green 7))
     ((green 3) 1 5 7) ==> (1 (green 3) 5 7)         ;; returns sorted result
     ((blue 7) (green 4)) ==> ((green 4) (blue 7))   ;; returns sorted result"
  (let (numbered-cand colored-cand color num result)
    (setf result nil)
    (cond
      ((integerp candidates)
       (setf result candidates))
      ((colored-candidate-p candidates)
       (setf result (second candidates))))
    (if (identity result) (return-from colors-if-bivalue-cell result))
    (setf numbered-cand nil)
    (setf colored-cand nil)
    (dolist (cand candidates)
      (cond
        ((integerp cand)
         (push cand numbered-cand))
        ((colored-candidate-p cand)
         (push cand colored-cand))
        (t (error "~sは不正な候補数字です。" cand))))
    (when (and (= (length candidates) 2) (= (length colored-cand) 1))
      ;;(format t "candidates = ~s, colored-cand = ~s~%" candidates colored-cand)
      (setf color (opposite-color (first (first colored-cand))))
      (setf num (first numbered-cand))
      ;;(format t "color = ~s, num = ~s~%" color num)
      (setf result (sort (push (list color num) colored-cand) #'colored-lessp))
      ;;(format t "result = ~s~%" result)
      (return-from colors-if-bivalue-cell result)
      )
    (return-from colors-if-bivalue-cell (sort (copy-seq candidates) #'colored-lessp))))

(defun set-color (colored-board cell num color)
"coloring用ボード[colored-board]のセル[cell]の要素のうち候補数字[num]
をカラー[color]とする。[num]は ([色名] [数字])という形式も可。"
  (let (candidate-list cand-color candidate)
    (setf candidate-list (aref colored-board (first cell) (second cell)) )
    (setf candidate-list (sort (copy-seq candidate-list) #'colored-lessp))
    (if (colored-candidate-p num) (setf num (second num)))
    (cond
      ((member (list color num) candidate-list :test 'equal)
       (do-nothing))
      ((member num candidate-list :test #'same-candidate-p)
       (setf cand-color (get-color colored-board cell num))
       (cond
         ((null cand-color)
          (setf candidate num))
         (t (setf candidate (list cand-color num))))
       (setf candidate-list
             (subst (list color num) candidate candidate-list :test #'equal))
       (setf (aref colored-board (first cell) (second cell)) candidate-list))
      (t (do-nothing)))
    (return-from set-color colored-board)))

(defun add-color (colored-board cell num-lst)
"彩色用ボード[colored-board]のセル[cell]に[num-lst]で指定される数値と一致する
彩色されていない候補数字があれば正しい色で彩色する。"
  (let (candidate color lst colored-candidate)
    ;; [candidate]              ::= ({[candidate] | ([colored-candidate]}...)
    ;; [colored-candidate]      ::= ([color-name] [candidate])
    ;; [candidate]              ::= [number]
    ;; [color-name]             ::= [atom]
    (setf candidate (aref colored-board (first cell) (second cell)))
    (setf colored-candidate (get-colors colored-board cell))
    (setf lst (intersection num-lst candidate)) 
    (cond
      ((and (pure-listp lst) (= (length lst) 1)
            (pure-listp colored-candidate) (= (length colored-candidate) 1))
       (setf color (first (first colored-candidate)))
       (setf colored-board (set-color colored-board cell (first lst) (opposite-color color))))
      ((and (pure-listp lst) (pure-listp colored-candidate)
            (>= (+ (length lst) (length colored-candidate)) 3))
       (error "add-color:[~a]を3色以上で塗ろうとしています。" (cell-addr cell)))
      (t (do-nothing)))
    (return-from add-color colored-board)))

(defun make-color-info (colored-board cell link-label color)
"リンク開始セルのための彩色情報を作成する。
[link-label] ::= ([label] ..) ;"
  (let (candidate-list color-info tmp diff)
    (if (not (link-labelp link-label)) (error "make-color-info:~s is not a link-label" link-label))
    (setf color-info nil)
    (parity-color color)
    (setf candidate-list (aref colored-board (first cell) (second cell)))
    (dolist (i candidate-list)
      (when (member i link-label :test 'equal)
        (push (list (parity-color) i) color-info)
        (exchange-parity-color)))
    (when (= (length candidate-list) 2) ;; bivalue-cell
      (setf diff (set-difference candidate-list (list (second (first color-info))) :test 'equal))
      (setf tmp (first (first color-info)))
      (setf color-info (adjoin (cons (opposite-color tmp) diff) color-info :test 'equal))
      )
    (return-from make-color-info (sort (copy-seq color-info) #'colored-lessp))))
  
(defun get-bivalue-elements (graph &optional (cell-list nil))
"グラフ[graph]内の指定されたセル群[cell-list]のうち2値(bivalue)セルの要素全体を返す。
[cell-list]が指定されていない場合は[cell-list]として[graph]の要素全体が指定されたものとする。
2番目の値として対象となった2値セルのアドレスのリストを返す。"
  (let (result bivalue-cells)
    (setf result nil bivalue-cells nil)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (when (and
               (typep (aref graph i j) 'vertex)
               (vertex-bivalue-cell (aref graph i j)))
          (cond
            ((null cell-list)
             (setf result (union (vertex-bivalue-cell (aref graph i j)) result))
             (setf bivalue-cells (union (list (list i j)) bivalue-cells :test #'equal)) )
            ((member (list i j) cell-list :test 'equal)
             (setf result (union (vertex-bivalue-cell (aref graph i j)) result))
             (setf bivalue-cells (union (list (list i j)) bivalue-cells :test #'equal)) )))))
    (debug-write "get-bivalue-elements" (format nil "bivalue-cells=~a~%" bivalue-cells))
    (return-from get-bivalue-elements (values result bivalue-cells))))

(defun print-colored-candidate (colored-candidate)
  (let (color-name candidate)
    (when (not (colored-candidate-p colored-candidate))
      (do-nothing)
      (return-from print-colored-candidate nil))
    (setf color-name (first colored-candidate))
    (setf candidate (second colored-candidate))
    (if (>= (color-mode) 1) (set-terminal-color (eval color-name)))
    (cond
      ((>= (color-mode) 2)
       (format t "~d" candidate))
      ((< (color-mode) 2)
       (format t "~c=~d" (short-color-name color-name) candidate)))
    (if (>= (color-mode) 1) (reset-terminal-color))
    (return-from print-colored-candidate nil)))

;; [planes]に含まれているすべての盤面を表示する。デバッグ用。
(defun print-planes (planes)
  (let (brd-lst len brd)
    (do ((i 1 (1+ i)))
        ((> i *board-size*))
      (setf brd-lst (aref planes i))
      (setf len (length brd-lst))
      (dotimes (j len)
        (setf brd (nth j brd-lst))
        (when (identity brd)
          (format t "(nth ~d (aref planes ~d)) = ~%" j i)
          (print-normal brd)
          (new-page) )))
    (return-from print-planes t) ) ) 

(defun short-color-name (p)
"定義された色名の短縮色名を返す。
ex. (short-color-name '*xcolor-red*) ==> #\R
    (short-color-name 'red) ==> #\R"
  (cond
    ((member p *user-authorized-color-list*)
     (cdr (assoc (cdr (assoc p *parity-color-list*)) *short-colors*)))
    ((member p (mapcar #'first *short-colors*))
     (cdr (assoc p *short-colors*)))
    (t (error "can't allow such color-name (~a)." p))))

(defun reverse-color-info (color-info)
"[color-info]の色の「反対色」のリストを返す。
((*BACKGROUND-COLOR-BLUE* 2) (*BACKGROUND-COLOR-YELLOW* 5) 7)
  ==> ((*BACKGROUND-COLOR-YELLOW* 2) (*BACKGROUND-COLOR-BLUE* 5) 7)"
  (let (result)
    (setf result nil)
    (dolist (num color-info)
      (cond
        ((integerp num)
         (push num result))
        ((colored-candidate-p num)
         (push
          (append (list (opposite-color (first num))) (list (second num)))
          ;;(append (set-difference *parity-colors* (list (first num))) (list (second num)))
          result))
        (t (push num result))))
    (return-from reverse-color-info (sort result #'colored-lessp))))

(defun link-labelp (lst)
"正しい形式のリンク・ラベルか否かを返す。"
  (if (null lst) (return-from link-labelp nil))
  (if (null (listp lst)) (return-from link-labelp nil))
  (dolist (i lst)
    (if (not (integerp i)) (return-from link-labelp nil)))
  ;;(if (> (length lst) 2) (return-from link-labelp nil))
  (return-from link-labelp t))

(defun get-color (colored-board cell num)
"指定したセル[cell]の候補数字[num]に設定されているパリティ・カラーを返す。
指定されたセルに指定された候補数字がない場合は[nil]を返す。
指定された候補数字がパリティ・カラーを持っていない場合も[nil]を返す。
example: if num = 3, (2 (green 3) 5 (blue 7) 8 9) ==> green"
  (let (lst)
    (setf lst (aref colored-board (first cell) (second cell)))
    (dolist (i lst)
      (if (and (listp i) (= (second i) num)) (return-from get-color (first i))))
    (return-from get-color nil)))

(defun get-colors (colored-board cell)
"指定されたセル[cell]に含まれるパリティ・カラーを持つ候補数字をパリティ・カラーと共に返す。
example: (2 (green 3) 5 (blue 7) 8 9) ==> ((green 3) (blue 7))"
  (let (lst (tmp nil))
    (setf lst (aref colored-board (first cell) (second cell)))
    (if (or (null lst) (integerp lst)) (return-from get-colors nil))
    (if (colored-candidate-p lst) (return-from get-colors lst))
    (dolist (i lst)
      (if (colored-candidate-p i) (push i tmp)))
    (return-from get-colors (sort tmp #'colored-lessp))))

(defun count-colors (candidates-list)
"候補数字のリスト[candidates-list]に含まれる彩色済み候補数字の個数を返す。"
  (let (result)
    (setf result 0)
    (dolist (num candidates-list)
      (if (colored-candidate-p num) (incf result)))
    (return-from count-colors result)))
  
(defun same-candidate-p (cand-0 cand-1)
"彩色された色情報をのぞいて等しい候補数字かどうかを返す。
[candidate] ::= [number] | [colored-candidate] ;
[colored-candidate] ::= ([color-name] [number]) ;
[color-name] ::= [atom] ;
ex.
  (same-candidate-p '7 '(blue 7)) ==> t
  (same-candidate-p '(blue 3) '(yellow 3)) ==> t
  (same-candidate-p '(red 7) '(red 3)) ==> nil"
  (cond
    ((or (null cand-0) (null cand-1))
     nil)
    ((and (integerp cand-0) (integerp cand-1))
     (= cand-0 cand-1))
    ((and (colored-candidate-p cand-0) (colored-candidate-p cand-1))
     (= (second cand-0) (second cand-1)))
    ((integerp cand-0)
     (= cand-0 (second cand-1)))
    ((integerp cand-1)
     (= (second cand-0) cand-1))
    (t (error "~%(same-candidate-p ~s ~s): invalid parameter.~%" cand-0 cand-1))))

(defun same-candidate-but-color-p (cand-0 cand-1)
"[cand-0]と[cand-1]が同じ値を持つ異なる色情報の候補数字かどうかを返す。
ex.
  (same-candidate-but-color-p '(blue 2) '(yellow 2)) ==> t
  (same-candidate-but-color-p '(blue 2) '(blue 2)) ==> nil
  (same-candidate-but-color-p '(red 5) '(blue 7)) ==> nil
  (same-candidate-but-color-p '(blue 3) 3) ==> nil
  (same-candidate-but-color-p '9 '9) ==> nil"
  (cond
    ((and
      (colored-candidate-p cand-0)
      (colored-candidate-p cand-1)
      (= (second cand-0) (second cand-1)))
     (not (equal (first cand-0) (first cand-1))))
    (t nil)))
    
(defun conflict-color-p (candidate)
"「矛盾色」形式の候補数字か否かを返す。"
  (cond
    ((and
      (pure-listp candidate)
      (= (length candidate) 2)
      (equal (first candidate) '*conflict-color*)
      (integerp (second candidate))) t)
    (t nil)))

(defun colored-candidate-p (candidate)
"彩色指定された候補数字か否かを返す。
[colored-candidate] ::= ([color-name] [number]) ;"
  (cond
    ((and
      (pure-listp candidate)
      (= (length candidate) 2)
      ;;(member (first candidate) *authorized-color-list*)
      (symbolp (first candidate))
      (integerp (second candidate))) t)
    (t nil)))

(defun colored-lessp (i j)
"「色指定された数値」を含む数値のリストの大小関係を判定して返す。
(sort '(8 9 (blue 3) 5 (green 2) 6 (green 3)) #'colored-lessp)
  ==> ((green 2) (green 3) (blue 3) 5 6 8 9)"
  (cond
    ((null i) t)
    ((null j) nil)
    ((colored-candidate-p i)
     (colored-lessp (second i) j))
    ((colored-candidate-p j)
     (colored-lessp i (second j)))
    ((and (integerp i) (integerp j))
     (< i j))
    (t nil)))

(defun color-order-p (i j)
"「色指定された数値」を含む数値のリストの大小関係を判定して返す。
数値が同じ場合は色名のアルファベット順で大小関係を判定する。
[colored-lessp]より「重い」。色名を無視して数値順に並べるなら[colored-lessp]を使う。
セル内には同じ候補数字は存在しないのでセル内の候補数字を比較するなら[colored-lessp]で十分。
(sort '(8 9 (blue 3) 5 (green 2) 6 (green 3)) #'colored-lessp)
  ==> ((green 2) (blue 3) (green 3) 5 6 8 9)
  \"BLUE\" < \"GREEN\""
  (cond
    ((null i) t)
    ((null j) nil)
    ((and (integerp i) (integerp j))
     (< i j))
    ((and (integerp i) (colored-candidate-p j))
     (< i (second j)))
    ((and (colored-candidate-p i) (integerp j))
     (< (second i) j))
    ((and (colored-candidate-p i) (colored-candidate-p j))
     (cond
       ((< (second i) (second j)) t)
       ((< (second j) (second i)) nil)
       ((= (second i) (second j))
        (string< (string (first i)) (string (first j))))))
    (t nil)))

(defun color-order-p-with-addr (i j)
"([cell-address] [colored-candidate])形式のデータを[cell-address]を無視して比較する。"
  (color-order-p (second i) (second j)))

(defun cell-less-p (cell-0 cell-1)
"セル[cell-0]が[cell-1]より「小さい」ならば[t]を返し、そうでないなら[nil]を返す。
セル同士の大小関係とは
    (1) 行番号が若い
    (2) 列番号が若い
(1)を優先する。つまり同じ行番号なら列番号が若い方を「小さい」とする。"
  (cond
    ((and (cell-addr-p cell-0) (cell-addr-p cell-1))
     (cell-less-p-sub cell-0 cell-1))
    (t nil)))

(defun cell-less-p-sub (cell-0 cell-1)
  (cond
    ((= (first cell-0) (first cell-1))
     (< (second cell-0) (second cell-1)))
    ((< (first cell-0) (first cell-1)))))

(defun cell-addr-p (cell-0 &optional (ext-or-int nil)) ;; [ext-or-int] ::= {external | internal} ;
  "引数が ([数字] [数字]) のセル・アドレス形態か否かを返す。"
  (if (and ;; 形式が合っているか？
       (pure-listp cell-0)
       (= (length cell-0) 2)
       (integerp (first cell-0))
       (integerp (second cell-0))
       )
      (cond ;; 形式があっていればセルのアドレス範囲が合っているか否かを判定。
	((or
	  (null ext-or-int)
	  (equal ext-or-int 'internal)
	  )
	 (and
	  (<= 0 (first cell-0) (1- (board-size)))
	  (<= 0 (second cell-0) (1- (board-size)))
	  )
	 )
	((equal ext-or-int 'external)
	 (and
	  (<= 1 (first cell-0) (board-size))
	  (<= 1 (second cell-0) (board-size))
	  )
	 )
	) ;; end cond
      nil ;; 形式が合っていなければ、その時点で[nil]。
      ) ;; end if
  ) ;; end cell-addr-p

(defun adj-list-less-p (adj-0 adj-1)
  (cell-less-p (first adj-0) (first adj-1)))

(defun print-elimination-board (board elm-list &optional (color '*elimination-color*))
"[elm-list]で指定された候補数字群を[color]で指定された色で彩色した盤面[board]を表示する。
[board]には変更を加えない。"
  (let (brd)
    ;; [elm-list] ::= ([elm-cand]...) ;
    ;; [elm-cand] ::= ([セル・アドレス] ([削除種類] ([number]))) ;
    ;; [削除種類] ::= cannotbe | mustbe ;
    ;;(format t "(print-elimination-board [board] ~s ~s)~%" elm-list color)
    (setf brd (new-board board)) ;; make new room.
    (dolist (elm-cand elm-list)
      (setf brd (set-color brd (first elm-cand) (second (second elm-cand)) color))
      )
    (print-normal brd)))

(defun print-eliminatable (&optional (val t sw))
"Advanced Coloringで削除対象の候補数字を彩色して表示するかどうかを設定する。
引数なしで実行すると現在の設定値を返す。"
  (cond
    ((null sw)
     *print-eliminatable*)
    (t (setf *print-eliminatable* val))))

(defun add-elimination-list (&optional (elm-list nil sw))
"削除可能データのリスト[elm-list]の要素が、まだ[*elimination-list*]の要素でなければ追加する。
引数に[nil]を指定すると[*elimination-list*]を[nil]に初期化する。
引数なしで実行すると現在の[*elimination-list*]を返す。"
  (cond
    ((null sw) *elimination-list*)
    ((null elm-list) (setf *elimination-list* nil))
    (t (setf *elimination-list* (union elm-list *elimination-list* :test #'equal)))) )

(defun reset-elimination-list ()
  (add-elimination-list nil))

(defun bivalue-cell-ratio (board)
"ボード[board]内の未確定セルに占める2値セルの割合を返す。"
  (let (num den candidate result)
    (setf num 0 den 0)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf candidate (aref board i j))
        (if (pure-listp candidate) (incf den))
        (if (and (pure-listp candidate) (= (length candidate) 2)) (incf num))))
    (cond
      ((zerop den)
       (setf result 0))
      (t (setf result (/ num den))))
    (return-from bivalue-cell-ratio result)))

(defun advanced-ratio (&optional (ratio 20/100 sw))
  (cond
    ((null sw)
     *advanced-ratio*)
    ((< 0 ratio 1)
     (setf *advanced-ratio* ratio))
    (t (error "advanced-ratio: shuld be (0 < ~s < 1)" ratio))))

(defun do-almost-locked-set (board)
"Almost Locked Setの実装

(rule 1) 2つのalmost-locked sets同士の間に2つのlinkが存在するならば、双方の集団内のすべての候補数字[K]を
見ることが出来る位置にある候補数字[K]は削除できる。

(Rule 2) 2つのalmost-locked setsが候補数字[i]を介してlinkしており、[i]とは異なる共通の候補数字[k]が存在
するならば、2つのalmost-locked sets内のすべての[k]を見ることが出来る位置にあるalmost-locked setsの要素
でない[k]は削除できる。"
  (let (brd result als-all-list als-comb-list als-a als-2 als-elm indep linked-labels common-cand
            rule-1-ok rule-2-ok lst result-list cells-1 cells-2 quiz-info quiz-info-list tmp)
    (if (finished-p board) (return-from do-almost-locked-set board))

    (setf result nil result-list nil)
    (setq quiz-info nil)
    (setq quiz-info-list nil)
    (setf brd (new-board board))
    (setf als-all-list (find-ALS brd))
    (if (and
         (integerp (als-check-limit))
         (> (comb (length als-all-list) 2) (als-check-limit)) )
        (return-from do-almost-locked-set brd)
	) ;; end if

    ;;(format t "als-all-list = ~s~%" als-all-list)
    (setf als-comb-list (combination als-all-list 2))
    (dolist (p als-comb-list)
      ;; [ALSを構成する組データ] ::= ( [種別] ([セル・アドレス] [セル内候補数字])... ) ;
      ;; [ALS-A]と[ALS-2]はセルを共有していてはならない。
      (setf als-a (first  p))
      (setf als-2 (second p))
      ;; [als-a]と[als-2]はセルを共有していてはならない。
      (setf cells-1 (collect-cells (cdr als-a)))
      (setf cells-2 (collect-cells (cdr als-2)))
      (setf indep (not (intersection cells-1 cells-2 :test #'equal)))
      (when (identity indep)
        (setf linked-labels (doubly-linked-p als-a als-2))
        (setf common-cand (single-linked-and-common-p als-a als-2))
        (setf rule-1-ok linked-labels)
        (setf rule-2-ok common-cand)
        ;;(setf rule-1-ok (and indep linked-labels))
        ;;(setf rule-2-ok (and indep common-cand))
        (cond
          ((identity rule-1-ok)
           (setf lst (candidate-addr (union (cdr als-a) (cdr als-2) :test #'equal)))
           ;; (can-see-all-the-candidates-for [lst] [brd]) ==> ( ([削除可能候補] [セルアドレス]...)... ) ;
           (setf als-elm (can-see-all-the-candidates-for lst brd))
           (when (identity als-elm)
             (push als-elm result)
             (push (list 'als-rule-1 als-a als-2 als-elm linked-labels) result-list))
           )
          ((identity rule-2-ok)
           ;; [candidate-addr返り値] ::= ( ([候補数字] [セルアドレス]...) ... ) ;
           (setf tmp (candidate-addr (union (cdr als-a) (cdr als-2) :test #'equal)))
           (setf lst nil)
           (dolist (q tmp)
             (if (member (first q) (second common-cand) :test #'equal) (push q lst)) )
           ;; (can-see-all-the-candidates-for [lst] [brd]) ==> ( ([削除可能候補] [セルアドレス]...)... ) ;
           (setf als-elm (can-see-all-the-candidates-for lst brd))
           (when (identity als-elm)
             (push als-elm result)
             (push (list 'als-rule-2 als-a als-2 als-elm (first common-cand) (second common-cand))
                   result-list))
           )
          (t (do-nothing)))
        ) ;;end when
      )   ;; end dolist

    ;;(format t "result-list = ~s~%" result-list)
    (when (identity result-list)
      ;; 冗長な情報を整理する(表示分のみ)。
      (when (not (als-show-all))
        (setf result-list (reduce-ALS-list result-list))
        )
      ;; Almost Locked Setに関する統計情報を表示する。
      (when (als-show-stat)
        (setf tmp (length als-all-list))
        (format t "この盤面には~d個のAlmost Locked Set(ALS)が存在します。~%" tmp)
        (format t "これら~d個のALSから2個を選ぶ組み合わせ~dパターンをチェックしました。~%" tmp (comb tmp 2))
        (format t "候補数字を削除可能なパターンは~d種類ありました。~%" (length result))
        (when (not (als-show-all))
          (format t "効率良く候補数字を削除できるパターンは~d種類です。~%" (length result-list))
          )
        )
      (dolist (p result-list)
        (case (first p)
          (als-rule-1
           (setf als-a (nth 1 p) als-2 (nth 2 p) als-elm (nth 3 p) linked-labels (nth 4 p))
           (plot-info "Almost Locked Set(r\#1)" *difficulty-ALS* 22)
           (method-applied 'do-almost-locked-set)
           (when (print-check)
             ;;(print-depth)
             ;;(format t "Almost Locked Setにより[~a]の位置から候補を削除できます。~%" *at-mark*)
             (format t "Almost Locked Set(r\#1)により")
             (cond
               ((and (show-color-board) (>= (color-mode) 1))
                (print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*))))
               (t (format t "[~a]" *at-mark*)))
             (format t "の位置から候補を削除できます。~%")
             (print-ALS-rule-1 brd als-a als-2 als-elm linked-labels)
	     ) ;; end when
	   (setq quiz-info (record-quiz-info-ALS-rule-1 als-a als-2 als-elm linked-labels))
	   (if quiz-info (push quiz-info quiz-info-list))
	   )
          (als-rule-2
           (setf als-a (nth 1 p) als-2 (nth 2 p) als-elm (nth 3 p) linked-labels (nth 4 p)
                 common-cand (nth 5 p))
           (plot-info "Almost Locked Set(r\#2)" *difficulty-ALS* 22)
           (method-applied 'do-almost-locked-set)
           (when (print-check)
             ;;(print-depth)
             ;;(format t "Almost Locked Setにより[~a]の位置から候補を削除できます。~%" *at-mark*)
             (format t "Almost Locked Set(r\#2)により")
             (cond
               ((and (show-color-board) (>= (color-mode) 1))
                (print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*))))
               (t (format t "[~a]" *at-mark*)))
             (format t "の位置から候補を削除できます。~%")
             (print-ALS-rule-2 brd als-a als-2 als-elm linked-labels common-cand))
	   )
	  (setq quiz-info (record-quiz-info-ALS-rule-2 als-a als-2 als-elm linked-labels common-cand))
	  (if quiz-info (push quiz-info quiz-info-list))
          ) ;; end case
        )   ;; end dolist
      (setf brd (do-elimination brd (make-ALS-elimination-list result)))
      (if (>= (explanation-level) 10) (print-board brd))
      ) ;; end when
    (return-from do-almost-locked-set (values (clean-up-board brd) (list (list quiz-info-list))))
    ) ;; end let
  ) ;; end do-almost-locked-set

(defun reduce-ALS-list (als-result)
"Almost Locked Setのリストを効率的な手筋のみに縮約する。効率的手筋は[efficient-ALS-p]が定義する。
[als-result]    ::= ( 'als-rule-1 [als-a] [als-2] [als-elm] [linked-labels] ) |
                    ( 'als-rule-2 [als-a] [als-2] [als-elm] [linked-labels] [common-cand] ) ;
[als-{1|2}]     ::= ([kind] ([セルアドレス] ([候補数字]...))...)
[kind]          ::= 'row | 'col | 'block ;
[als-elm]       ::= ( ([削除可能候補] [セルアドレス]...)... ) ;
[linked-labels] ::= ([link-label]) | ([link-label] [link-label]) ;
[common-cand]   ::= ([候補数字]...) ;"
  (let (als-elm-1 als-elm-2 result lst len i p)
    (if (null als-result) (return-from reduce-ALS-list nil))
    (if (= (length als-result) 1) (return-from reduce-ALS-list als-result))
    (setf lst (sort (copy-seq als-result) #'(lambda (x y) (list-lessp (nth 3 x) (nth 3 y)))))
    ;;(format t "reduce-ALS-list:sorted = ~s~%" lst)

    (setf result nil i 0 len (length lst))
    (loop
       (catch 'junk
         (setf p (nth i lst))
         (setf als-elm-1 (nth 3 p))
         ;;(format t "als-elm-1(~d) = ~s~%" i als-elm-1)
         (incf i)
         (if (> i len) (return))
         (dolist (q (nthcdr i lst))
           (setf als-elm-2 (nth 3 q))
           ;;(format t "als-elm-2 = ~s~%" als-elm-2)
           (cond
             ((list-subsetp als-elm-1 als-elm-2)
              (throw 'junk nil) )
             ((and
               (equal als-elm-1 als-elm-2)
               (efficient-ALS-p q p))
              (throw 'junk nil) )
             ) ;;end cond
           )   ;;end dolist
         (push p result)
         )
       )
    (return-from reduce-ALS-list result)))

(defun efficient-ALS-p (als-result-1 als-result-2)
"[als-result-1]が[als-result-2]より\"効率的\"なAlmost Locked Setの手筋か否かを返す。
効率的手筋とは、共通の候補数字を削除できる場合
  ・より多くの候補数字を一括削除できる方が効率的。
      ==> 自明。
  ・[single-linked]の方が[doubly-linked]よりも効率的。
      ==> 2つの相互リンクを見つけるよりも、１つの相互リンクと１つの共通候補を見つける方が楽。
  ・2つのALSのセル数の2乗の和が小さい方が効率的。
      ==> 2つのALSの合計セル数が同じ場合、大きなALSを発見するよりコンパクトなALSを2つ発見する方が楽。
と定義する。共通の候補数字を削除できない場合は「効率的」と判断できないので[nil]。

[als-result-{a|b}] ::= ( 'als-rule-1 [als-a] [als-2] [als-elm] [linked-labels] ) |
                       ( 'als-rule-2 [als-a] [als-2] [als-elm] [linked-labels] [common-cand] ) ;
[als-{1|2}]        ::= ([kind] ([セルアドレス] ([候補数字]...))...)
[kind]             ::= 'row | 'col | 'block ;
[als-elm]          ::= ( ([削除可能候補] [セルアドレス]...)... ) ;
[linked-labels]    ::= ([link-label]) | ([link-label] [link-label]) ;
[common-cand]      ::= ([候補数字]...) ;
[single-linked]    ::= (eq (first [als-result-{1|2}]) 'als-rule-1) == [t] ;
[doubly-linked]    ::= (eq (first [als-result-{1|2}]) 'als-rule-2) == [t] ;"
  (let (als-elm-1 als-elm-2 als-cand-11 als-cand-12 als-cand-21 als-cand-22 sq-sum-1 sq-sum-2)
    (setf als-elm-1 (nth 3 als-result-1) als-elm-2 (nth 3 als-result-2))
    (cond
      ;; 共通の候補数字を削除できない場合は[nil]。
      ((not (is-common-candidate-p als-elm-1 als-elm-2)) nil)
      ;; より多くの候補数字を一括削除できる方が効率的。
      ((> (length als-elm-1) (length als-elm-2)) t)
      ((< (length als-elm-1) (length als-elm-2)) nil)
      ((= (length als-elm-1) (length als-elm-2))
       (cond
         ;; [single-linked]の方が[doubly-linked]よりも効率的。
         ((and
           (eq (first als-result-1) 'als-rule-1)
           (eq (first als-result-2) 'als-rule-2) t))
         ((and
           (eq (first als-result-1) 'als-rule-2)
           (eq (first als-result-2) 'als-rule-1) nil))
         (t
          ;; 2つのALSのセル数の2乗の和が小さい方が効率的。
          (setf als-cand-11 (length (cdr (nth 1 als-result-1))))
          (setf als-cand-12 (length (cdr (nth 2 als-result-1))))
          (setf als-cand-21 (length (cdr (nth 1 als-result-2))))
          (setf als-cand-22 (length (cdr (nth 2 als-result-2))))
          (setf sq-sum-1 (+ (expt als-cand-11 2) (expt als-cand-12 2)))
          (setf sq-sum-2 (+ (expt als-cand-21 2) (expt als-cand-22 2)))
          (cond
            ((< sq-sum-1 sq-sum-2) t)
            (t nil))))))))

(defun list-subsetp (lst-1 lst-2)
  (dolist (p lst-1)
    (dolist (q lst-2)
      (if (subsetp p q :test #'equal) (return-from list-subsetp t))
      )
    )
  (return-from list-subsetp nil))

(defun purely-subsetp (set-1 set-2)
"[set-1]が[set-2]の真部分集合か否かを返す。"
  (cond
    ((not (subsetp set-1 set-2 :test #'equal)) nil)
    (t (< (length set-1) (length set-2)))))

(defun is-common-candidate-p (als-elm-1 als-elm-2)
"共通のセルアドレスに共通の候補数字を持っているかどうかを返す。
[als-elm]          ::= ( ([削除可能候補] [セルアドレス]...)... ) ;"
  (dolist (p als-elm-1)
    (dolist (q als-elm-2)
      (if (/= (first p) (first q)) (return))
      (if (intersection (rest p) (rest q) :test #'equal) (return-from is-common-candidate-p t))
      )
    )
  (return-from is-common-candidate-p nil))

(defun make-ALS-elimination-list (can-see-list)
"与えられた削除可能候補のリスト[can-see-list]を、関数[do-elimination]で処理できる形式の
削除可能候補のリストに変換する。

[can-see-list] ::= ([ALS-list]...) ;
[ALS-list] ::= ( ([削除可能候補数字] [セルアドレス]...)... ) | nil;
[返り値] ::= ([削除可能データ]...) | nil ;
[削除可能データ] ::= ([セル・アドレス] ([削除種類] [削除可能候補])) ;
[削除種類] ::= cannotbe | mustbe ;
[削除可能候補] ::= [数字] ;

((5 (4 2) (5 1) (6 0)) (9 (4 2))) ;r5c3,r6c2,r7c1の5, r5c3の9は削除できるという意味。
  ==> ( ((4 2) (cannotbe 5)) ((5 1) (cannotbe 5)) ((6 0) (cannotbe 5)) ((4 2) (cannotbe 9)) )"
  (let (cell-list cand result tmp)
    (setf result nil)
    (dolist (als-list can-see-list)
      (dolist (p als-list)
        (setf cand (first p))
        (setf cell-list (cdr p))
        (setf tmp nil)
        (dolist (q cell-list)
          (push (list q (list 'cannotbe cand)) tmp)
          )
        (if (identity tmp) (setf result (append result tmp)))
        )
      )
    (return-from make-ALS-elimination-list result)))

(defun print-ALS-rule-1 (brd als-a als-b als-elm linked-labels)
"Almost Locked Set [als-a]と[als-2]のすべての要素[k]を見ることが出来る候補[k]を含むセルアドレス
を示す盤面を表示する。
[als-{1|2}] ::= ( [種別] ([セル・アドレス] [セル内候補数字])... ) ;
[als-elm] ::= ( ([削除可能候補] [セルアドレス]...)... ) ;

rule-1 : doubly-linked."
  (let (chk-brd c-brd row col elm-data len p q cell cand-list als-a-rest als-b-rest tmp)
    (setf chk-brd (make-null-check-board))
    (setf c-brd (new-board brd)) ;; colored board.

    (setf cand-list (collect-candidates (cdr als-a)))
    (setf als-a-rest (cdr als-a))
    (setf len (length als-a-rest))

    (dotimes (i len) ;; Almost Locked Set data.
      (setf p (nth i als-a-rest))
      (setf cell (first p))
      ;;(push cell als-a) ;; 2024-04-12
      (setf row (first cell) col (second cell))
      (setf (aref chk-brd row col) *sharp-mark*)
      (cond
        ((show-color-board)
         (print-colored-string 'blue (format nil "~a" (cell-addr cell))))
        (t (format t "~a" (cell-addr cell))))
      (setf c-brd (set-colored-all-candidates c-brd (list row col) 'blue)) ;; 2024-01-25
      (setf (aref c-brd row col) (cons 'blue (aref c-brd row col)))
      (if (< i (1- len)) (format t ","))
      ) ;; end dotimes
;;
;; SBCL 2.2.9.debianおよびSBCL 2.4.1では
;;
;; (declaim (optimize (safety 0) (speed 3) (space 0) (compilation-speed 0)))
;; (declaim (optimize (safety 3) (speed 0) (space 0) (compilation-speed 0)))
;;
;; のどちらでも、format式直前のdebug-write式が無効の場合は以下のような不正な出力となる。
;;
;;       r4c8,r5c8,r6c9の候補数字はAlmost Locked Set [B]=(2
;;              3
;;
;;              6
;;
;;              7)を構成しています。
;;
;; format式直前のdebug-write式が有効な(=印字出力がある)場合は正常に
;;
;;       r4c8,r5c8,r6c9の候補数字はAlmost Locked Set [B]=(2 3 6 7)を構成しています。
;;
;; と出力される。format式の前後両方に(finish-output)を書いても変化なし。[cand-list]を[copy-seq]で
;; 値渡しを強制しても変化なし。CLISPでは問題なし。
;;
;;       (format t "の候補数字はAlmost Locked Set [A]=")
;;       (format t "~aを構成しています。~%" cand-list)
;;
;; とformat式を分離して[cand-list]出力前に別の出力が行われるようにしてもダメ。(listp cand-list)は[t]。
;;
;;       (setq tmp *print-pretty*) ;; *print-pretty*の現在の設定を保存。
;;       (setq *print-pretty* nil) ;; *print-pretty*をオフ。
;;       (format t "の候補数字はAlmost Locked Set [A]=~aを構成しています。~%" cand-list)
;;       (finish-output) ;; for SBCL opt=3
;;       (setq *print-pretty* tmp) ;; *print-pretty*の値を復旧。
;;
;; とpretty printをオフにしてもダメ。
;;
;; (reset-terminal-color)を件のformat式の直前に入れてもダメ。[put-color-string]は関係なさそう。
;;
;; format式の直前に(format t ""), (format t " ")を入れるが、いずれも効果なし。
;;
;; (setf tmp (format nil "の候補数字はAlmost Locked Set \*[A]=~aを構成しています。~%" cand-list))
;; (write tmp :stream t :escape nil :pretty nil)
;;
;; もダメ。何もしない関数(do-nothing)を直前に入れても[nil]を入れてもダメ。
;;
;; リストの要素を"("と")"で囲んで要素ごとに出力する関数[print-list]を作成してバグを回避した。
;;
    (cond
      ((show-color-board)
       (debug-write "SBCL-print-ALS-rule-1" (format nil " cand-list=~a" cand-list))
       ;; 本来は
       ;;(format t "の候補数字はAlmost Locked Set [A]=~aを構成しています。~%" cand-list)
       (format t "の候補数字はAlmost Locked Set [A]=") (print-list cand-list)
       (format t "を構成しています。~%")
       (finish-output)
       )
      (t
       (format t "の候補数字[~a]はAlmost Locked Set [A]=" *sharp-mark*) (print-list cand-list)
       (format t "を構成しています。~%")
       (finish-output)
       )
      )

    (setf cand-list (collect-candidates (cdr als-b)))
    (setf als-b-rest (cdr als-b))
    (setf len (length als-b-rest))
    (dotimes (i len) ;; Almost Locked Set secondary data.
      (setf p (nth i als-b-rest))
      (setf cell (first p))
      ;;(push cell als-b)
      (setf row (first cell) col (second cell))
      (setf (aref chk-brd row col) *dollar-mark*)
      (cond
        ((show-color-board)
         (print-colored-string 'green (format nil "~a" (cell-addr cell))))
        (t (format t "~a" (cell-addr cell))))
      (debug-write "print-ALS-rule-1-1" (format nil "c-brd=~a" c-brd))
      (setf c-brd (set-colored-all-candidates c-brd (list row col) 'green)) ;; 2024-01-25
      (setf (aref c-brd row col) (cons 'green (aref c-brd row col)))
      (debug-write "print-ALS-rule-1-2" (format nil "c-brd=~a" c-brd))
      (if (< i (1- len)) (format t ","))
      )
    (cond
      ((show-color-board)
       (debug-write "SBCL-print-ALS-rule-1" (format nil "cand-list=~s" cand-list))
       ;;(format t "の候補数字はAlmost Locked Set [B]=~aを構成しています。~%" cand-list)
       (format t "の候補数字はAlmost Locked Set [B]=") (print-list cand-list)
       (format t "を構成しています。~%")
       (finish-output)
       )
      (t
       (format t "の候補数字[~a]はAlmost Locked Set [B]=" *dollar-mark*) (print-list cand-list)
       (format t "を構成しています。~%")
       (finish-output)
       )
      )

    (format t "Almost Locked Set[A]と[B]は候補数字~aにより相互にリンクしています。~%" (first linked-labels))
    (finish-output)

    ;;(setq als-link-label (first linked-labels))
    ;;(record-quiz-info :position (list (reverse als-a) (reverse als-b) als-link-label))

    (let (cells cells-list)
      (setq cells-list nil)
      (dolist (p als-elm)
	(setq cells nil) ;; 2024-04-12
	(setf elm-data (first p))
	;;(push elm-data cells) ;; 2024-04-12
	(setf tmp (cdr p))
	(setf len (length tmp))
	(format t "  ==> ")
	(dotimes (i len)
          (setf q (nth i tmp))
	  ;;(push q cells) ;; 2024-04-12
          (setf row (first q) col (second q))
          (setf (aref chk-brd row col) *at-mark*)
          (format t "~a" (cell-addr q))
          (setf c-brd (set-colored-candidate c-brd q elm-data '*elimination-color*))
          (if (< i (1- len)) (format t ","))
          )
	(format t "の")
	(cond
          ((show-color-board)
           (print-colored-string 'red (format nil "[~d]" elm-data)))
          (t (format t "[~d]" elm-data)))
	(finish-output)
	(format t "はAlmost Locked Set内のすべての[~d]を見ることができるので削除できます。~%" elm-data)
	(finish-output)
	(push (reverse cells) cells-list) ;; 2024-04-12
	)
      ) ;; end let

    ;;(record-quiz-info :candidate (reverse cells-list))

    (debug-write "print-ALS-rule-1-3" (format nil "c-brd=~a" c-brd))
    (cond
      ((show-color-board)
       (print-normal c-brd))
      (t (print-mini chk-brd))
      )

    ;;(setq quiz-info (record-quiz-info))
    ;;(reset-record-quiz-info)
    (return-from print-ALS-rule-1 t)
    )
  ) ;; end print-ALS-rule-1

(defun print-ALS-rule-2 (brd als-a als-b als-elm linked-label common-cand) 
"rule-2 : single-linked and common candidates."
  (let (chk-brd c-brd cell row col elm-data cand-list len als-a-rest als-b-rest p q tmp)
    (setf chk-brd (make-null-check-board))
    (setf c-brd (new-board brd)) ;; colored board.

    (setf cand-list (collect-candidates (cdr als-a)))
    (setf als-a-rest (cdr als-a))
    (setf len (length als-a-rest))
    (dotimes (i len) ;; Almost Locked Set data.
      (setf p (nth i als-a-rest))
      (setf cell (first p))
      (setf row (first cell) col (second cell))
      (setf (aref chk-brd row col) *sharp-mark*)
      (cond
        ((show-color-board)
         (print-colored-string 'blue (format nil "~a" (cell-addr cell))))
        (t (format t "~a" (cell-addr cell))))
      (debug-write "print-ALS-rule-2-1" (format nil "c-brd=~a" c-brd))
      (setf c-brd (set-colored-all-candidates c-brd (list row col) 'blue)) ;; 2024-01-25
      (setf (aref c-brd row col) (cons 'blue (aref c-brd row col)))
      (debug-write "print-ALS-rule-2-2" (format nil "c-brd=~a" c-brd))
      (if (< i (1- len)) (format t ","))
      )
    (cond
      ((show-color-board)
       (debug-write "SBCL-print-ALS-rule-1" (format nil "cand-list=~a" cand-list))
       (format t "の候補数字はAlmost Locked Set [A]=") (print-list cand-list)
       (format t "を構成しています。~%")
       (finish-output)
       )
      (t
       (format t "の候補数字[~a]はAlmost Locked Set [A]=" *sharp-mark*) (print-list cand-list)
       (format t "を構成しています。~%")
       (finish-output)
       )
      )

    (setf cand-list (collect-candidates (cdr als-b)))
    (setf als-b-rest (cdr als-b))
    (setf len (length als-b-rest))
    (dotimes (i len) ;; Almost Locked Set secondary data.
      (setf p (nth i als-b-rest))
      (setf cell (first p))
      (setf row (first cell) col (second cell))
      (setf (aref chk-brd row col) *dollar-mark*)
      (cond
        ((show-color-board)
         (print-colored-string 'green (format nil "~a" (cell-addr cell))))
        (t (format t "~a" (cell-addr cell))))
      (debug-write "print-ALS-rule-2-3" (format nil "c-brd=~a" c-brd))
      (setf c-brd (set-colored-all-candidates c-brd (list row col) 'green)) ;; 2024-01-25
      (setf (aref c-brd row col) (cons 'green (aref c-brd row col)))
      (debug-write "print-ALS-rule-2-4" (format nil "c-brd=~a" c-brd))
      (if (< i (1- len)) (format t ","))
      )
    (cond
      ((show-color-board)
       (debug-write "SBCL-print-ALS-rule-1" (format nil "cand-list=~a" cand-list))
       (format t "の候補数字はAlmost Locked Set [B]=") (print-list cand-list)
       (format t "を構成しています。~%")
       (finish-output)
       )
      (t
       (format t "の候補数字[~a]はAlmost Locked Set [B]=" *dollar-mark*) (print-list cand-list)
       (format t "を構成しています。~%")
       (finish-output)
       )
      )

    (format t "Almost Locked Set[A]と[B]は候補数字~aにより相互にリンクし,共通の候補数字~aが存在します。~%"
            linked-label common-cand)
    (finish-output)

    (dolist (p als-elm)
      (setf elm-data (first p))
      (setf tmp (cdr p))
      (setf len (length tmp))
      (format t "  ==> ")
      (dotimes (i len)
        (setf q (nth i tmp))
        (setf row (first q) col (second q))
        (setf (aref chk-brd row col) *at-mark*)
        (format t "~a" (cell-addr q))
        (setf c-brd (set-colored-candidate c-brd q elm-data '*elimination-color*))
        (if (< i (1- len)) (format t ","))
        )
      (format t "の")
      (cond
        ((show-color-board)
         (print-colored-string 'red (format nil "[~d]" elm-data)))
        (t (format t "[~d]" elm-data)))
      (format t "はAlmost Locked Set内のすべての[~d]を見ることができるので削除できます。~%" elm-data)
      (finish-output)
      )
    (cond
      ((and (>= (color-mode) 1) (show-color-board))
       (print-normal c-brd))
      (t (print-mini chk-brd)))
    (return-from print-ALS-rule-2 t)))

(defun record-quiz-info-ALS-rule-1 (als-a als-b als-elm linked-labels)
  (let (elm-data len q als-a-2 als-b-2 quiz-info cells del-cells-list cannotbe-list tmp)

    ;; [als-{a|b}] ::= ( ({row|col|block} (([cell-addr] ([candidate]+))+))+ ) ;
    ;; for example '(block ((0 6) (2 5 6)) ((2 6) (2 5 6))) '(block ((4 6) (2 6))) '((2 (8 6))) '((2 6)))

    (setq als-a-2 nil)
    (setq als-b-2 nil)
    (setq quiz-info nil)

    (record-quiz-info :function-name 'do-almost-locked-set)
    (record-quiz-info :explanation *ALS-rule-1*)

    (dolist (p (rest als-a))
      (push (first p) als-a-2)
      )

    (debug-write "record-quiz-info-ALS-rule-1" (format nil "als-a-2=~a~%" als-a-2))

    (dolist (p (rest als-b))
      (push (first p) als-b-2)
      )
    
    (debug-write "record-quiz-info-ALS-rule-1" (format nil "als-b-2=~a~%" als-b-2))
    (debug-write "record-quiz-info-ALS-rule-1" (format nil "linked-labels=~a~%" linked-labels))

    ;; Almost Locked Set [A]とAlmost Locked Set [B]、そしてリンク要素の候補数字を記録する。
    ;; [linked-labels] ::= ( [pair of candidate] ) ;
    (record-quiz-info :position (list (reverse als-a-2) (reverse als-b-2) (first linked-labels)))

    (setq del-cells-list nil)
    (dolist (p als-elm)
      (setq cells nil) ;; 2024-04-12
      (setf elm-data (first p))
      (push elm-data cells) ;; 2024-04-12
      (setf tmp (cdr p))
      (setf len (length tmp))
      (dotimes (i len)
        (setf q (nth i tmp))
	(push q cells)			;; 2024-04-12
        )				;; end dolist
      (push (reverse cells) del-cells-list)	;; 2024-04-12
      )					;; end dolist

    (debug-write "record-quiz-info-ALS-rule-1" (format nil "del-cells-list=~a~%" del-cells-list))

    ;; [del-cells-list] ::= ( ([candidate] [cell-addr]+)+ );
    (setq cannotbe-list nil)
    (dolist (p (reverse del-cells-list)) ;; [p] ::= ([candidate] [cell-addr]+) ;
      (dolist (q (rest p)) ;; [(rest p)] ::= ((cell-addr]+) ; [q] ::= [cell-addr] ;
	(push (list 'cannotbe q (list (first p))) cannotbe-list)
	) ;; end dolist
      ) ;; end dolist

    (record-quiz-info :candidate cannotbe-list)

    (debug-write "record-quiz-info-ALS-rule-1" (format nil "cannotbe-list=~a~%" cannotbe-list))

    (setq quiz-info (record-quiz-info))
    ;;(format t "quiz-info=~s~%" quiz-info)
    (reset-record-quiz-info)
    (return-from record-quiz-info-ALS-rule-1 quiz-info)
    ) ;; end let
  ) ;; end record-quiz-info-ALS-rule-1

(defun record-quiz-info-ALS-rule-2 (als-a als-b als-elm linked-label common-cand) 
"rule-2 : single-linked and common candidates."
  (let (elm-data len q als-a-2 als-b-2 cells del-cells-list cannotbe-list quiz-info tmp)

    (setq als-a-2 nil)
    (setq als-b-2 nil)
    (setq quiz-info nil)

    (record-quiz-info :function-name 'do-almost-locked-set)
    (record-quiz-info :explanation *ALS-rule-2*)

    (dolist (p (rest als-a))
      (push (first p) als-a-2)
      )

    (dolist (p (rest als-b))
      (push (first p) als-b-2)
      )

    ;;(format t "Almost Locked Set[A]と[B]は候補数字~aにより相互にリンクし,共通の候補数字~aが存在します。~%"
    ;;        linked-label common-cand)
    ;;(record-quiz-info :position (list (reverse als-a-2) (reverse als-b-2) linked-label common-cand))
    (record-quiz-info :position (list (reverse als-a-2) (reverse als-b-2) linked-label common-cand))

    (setq del-cells-list nil)
    (dolist (p als-elm)
      (setq cells nil)
      (setf elm-data (first p))
      (push elm-data cells)
      (setf tmp (cdr p))
      (setf len (length tmp))
      (dotimes (i len)
        (setf q (nth i tmp))
	(push q cells)
        ) ;; end dolist
      (push (reverse cells) del-cells-list)
      ) ;; end dolist

    ;; [del-cells-list] ::= ( ([candidate] [cell-addr]+)+ );
    (setq cannotbe-list nil)
    (dolist (p (reverse del-cells-list)) ;; [p] ::= ([candidate] [cell-addr]+) ;
      (dolist (q (rest p)) ;; [(rest p)] ::= ((cell-addr]+) ; [q] ::= [cell-addr] ;
	(push (list 'cannotbe q (list (first p))) cannotbe-list)
	) ;; end dolist
      ) ;; end dolist
    (setq cannotbe-list (reverse cannotbe-list))

    (record-quiz-info :candidate cannotbe-list)
    
    (setq quiz-info (record-quiz-info))
    ;;(format t "quiz-info=~s~%" quiz-info)
    (reset-record-quiz-info)

    (return-from record-quiz-info-ALS-rule-2 quiz-info)
    ) ;; end let
  ) ;; end record-quiz-info-ALS-rule-2

(defun find-ALS (board)
"盤面からAlmost Locked Setsデータを抽出する。

[結果] ::= ([行内でALSを構成する組データ]...) と
           ([列内でALSを構成する組データ]...) と
           ([ブロック内でALSを構成する組データ]...) の和集合
[ALSを構成する組データ] ::= ( [種別] ([セル・アドレス] [セル内候補数字])... ) ;
[種別] ::= 'row | 'col | 'block ;
ex.( (row ((1 1) (5 9)) ((1 2) (5 9)) ((1 6) (7 8)) ((1 7) (3 7 8)))
     (col ((4 8) (5 7)) ((5 8) (1 5 7 8)) ((7 8) (3 5 8)) ((8 8) (1 3 5 7 8)))
     (block ((2 1) (7 8))) (block ((2 0) (3 8))) (block ((1 2) (5 9))) )"
  (let (result als-row als-col als-block)
    (setf als-row nil als-col nil als-block nil)
    (setf result (find-ALS-sub board 'row))
    (setf result (union result (find-ALS-sub board 'col) :test #'(lambda (p q) (equal (cdr p) (cdr q)))))
    (setf result (union result (find-ALS-sub board 'block) :test #'(lambda (p q) (equal (cdr p) (cdr q)))))
    (dolist (p result)
      (case (first p)
        (row (push p als-row))
        (col (push p als-col))
        (block (push p als-block))
        (otherwise (do-nothing))))
    (return-from find-ALS result)))

(defun find-ALS-sub (board kind)
  (let (brd cells-with-candidates candidates cmblist als-lst)
    (setf brd (new-board board))
    (setf als-lst nil)
    (dotimes (i *board-size*)
      (setf cells-with-candidates 0)
      (setf candidates nil)
      (let (cell row col q)
        (dotimes (j *board-size*) ;;[i]行[j]列/[j]行[i]列/ブロック[i]#[j]に存在する候補を集計。
          (cond
            ((equal kind 'row)
             (setf row i)
             (setf col j))
            ((equal kind 'col)
             (setf row j)
             (setf col i))
            ((equal kind 'block)
             (setf row (+ (block-base-row i) (floor j *block-size*)))
             (setf col (+ (block-base-col i) (mod j *block-size*))))
            (t (error "can't happen. stop at find-ALS-sub(1).")))
          (setf cell (aref brd row col))
          (when (pure-listp cell)
            ;;候補を持つセル数をカウントしておく。
            (incf cells-with-candidates)
            ;;[cand-with-addr] ::= ( ([row-addr] [col-addr]) ([candidate-list]) ) ;
            ;;[candidates_n] ::= ( [cand-with-addr_1] ... [cand-with-addr_n] ) ;
            (push (list (list row col) cell) candidates)
            )
          ) ;;候補集計終了。[candidates]にセル・アドレス付きで集計されている。

        ;;(format t "~%*** candidates = ~a~%~%" candidates)
        (dotimes (k cells-with-candidates)
          ;;[n]個のセル・アドレス付き候補の組から[1]〜[cells-with-candidates]個を選んだ組み合わせのリスト
          ;;のそれぞれに対してAlmost Locked setを抽出する。
          (setf cmblist (combination candidates (1+ k)))
          ;;(format t "cmblist=~a, length = ~d~%" cmblist (length cmblist))
          ;;[cmblist_k] ::= ( [candidates_1] ... [candidates_k] ) ;
          (dotimes (p (length cmblist))
            (setf q (nth p cmblist)) ;;[q] ::= [candidates_n] where n=p+1 ;
            ;;(format t "(nth ~d cmblist) = ~a~%" p q)
            (when (almost-locked-set-p (mapcar #'second q))
              (setf q (sort (copy-seq q) #'(lambda (x y) (cell-order-p (car x) (car y)))))
              (setf als-lst (union als-lst (list (push kind q)) :test #'equal))
              ;;(format t "@q = ~a~%" q)
              ;;(format t "@als-lst = ~a~%" als-lst)
              )
            ) ;;end dotimes
          ) ;;end dotimes

        ) ;;end let
      ) ;;end dotimes
    (return-from find-ALS-sub als-lst)))

 ;; end record-quiz-info-ALS-rule-1

(defun almost-locked-set-p (lst)
"セル内の候補数字のリストからなるリスト[lst]がalmost-locked setであるかどうかを判定する。
[lst]内のすべてのセルが同一の行・列・ブロックのいずれかに含まれているものとする。
almost-locked setである場合はalmost-locked-setを構成する要素のリストを返す。
そうでない場合は[nil]を返す。[lst]が[nil]の場合は[nil]を返す。"
  (let (len p result)
    (if (null lst) (return-from almost-locked-set-p nil))
    (setf len (length lst))
    (setf p nil)
    (dotimes (i len)
      (setf p (union p (nth i lst) :test #'equal)))
    (cond
      ((= (length p) (1+ len))
       (setf result (sort (copy-seq p) #'<)))
      (t (setf result nil)))
    (when (debug-write-p "almost-locked-set-p")
      (format t "(almost-locked-set-p ~a) returns " lst)
      (format t "~a~%" result) )
    (return-from almost-locked-set-p result)))

(defun doubly-linked-p (ALS-A ALS-B)
"2つのAlmost Locked Set [ALS-A]と[ALS-B]の間に2つ(以上)のリンクが存在するか否かを返す。
2つのリンクが存在する場合はセルアドレスとリンクしている候補数字のペアを返す。そうでない場合は[nil]を返す。
定義 [リンク] ::= 2つのセルAとBが同じユニットに属し、共通の候補数字を持つときAとBはリンクしていると呼ぶ。
[ALS-i] ::= ([kind] ([セルアドレス] ([候補数字]...))...)
[kind] ::= 'row | 'col | 'block ; 
[返り値] ::= ([リンクラベルのペア]...) | nil ;
[リンクラベルのペア] ::= ([リンクしている候補数字] [リンクしている候補数字]) ;"
  (let (cand-1 cand-2 link-labels two-labels cells-1 cells-2 result answer tmp)
    (setf cand-1 (collect-candidates (cdr ALS-A)))
    (setf cand-2 (collect-candidates (cdr ALS-B)))
    ;; [link-labels] ::= リンク・ラベル候補 ;
    (setf link-labels (intersection cand-1 cand-2 :test #'=))
    ;; restricted commonは2個以上の候補数字が存在しなければ存在し得ない。。
    (if (< (length link-labels) 2) (return-from doubly-linked-p nil))
    ;;(format t "link-labels = ~a~%" link-labels)
    (setf answer nil)
    (setf two-labels (combination link-labels 2))
    (dolist (p two-labels)
      (setf result nil)
      (dolist (q p)
        ;; [cells-1], [cells-2]にはリンク･ラベル[p]を含む[ALS-A], [ALS-B]それぞれのセル･アドレスのリストが入る。
        (setf cells-1 nil cells-2 nil)
        (dolist (r (cdr ALS-A))
          (if (member q (second r) :test #'=) (push (first r) cells-1)))
        (dolist (r (cdr ALS-B))
          (if (member q (second r) :test #'=) (push (first r) cells-2)))
        (setf tmp (all-same-unit-p (append cells-1 cells-2)))
        (if (identity tmp) (push tmp result))
        ) ;; end dolist
      ;; 要素が2つあり、かつ共通の要素を持つかをチェックする。
      ;; ((row) (row)), ((block row) (row)) などはOK。
      (when (and (= (length result) 2) (intersection (first result) (second result)))
        (push p answer)
        ) ;;end when
      ) ;;end dolist
    (return-from doubly-linked-p answer)))

(defun single-linked-and-common-p (ALS-A ALS-B)
"2つのAlmost Locked Setが候補数字[i]を介して相互リンクしており、[i]とは異なる共通の候補数字[k]が
存在するか否かを返す。
[ALS-i] ::= ([kind] ([セルアドレス] ([候補数字]...))...)
[返り値] ::= ( ([リンクラベル]...) ([リンクラベルとは異なる共通の候補数字]...) ) | nil ;
※複数の共通候補数字がすべて相互リンクのラベルである場合は相互二重リンク。この場合、相互リンク
としては[nil]を返す。
ex.
(single-linked-and-common-p
 '(block ((3 1) (7 8 9)) ((3 2) (1 7 8)) ((4 0) (5 9)) ((5 0) (5 8)))
 '(row ((3 5) (1 7))))
  ==> ((7 1) nil) ==> nil"
  (let (cand-1 cand-2 common-cand cells-1 cells-2 result answer tmp)
    (setf cand-1 (collect-candidates (cdr ALS-A)))
    (setf cand-2 (collect-candidates (cdr ALS-B)))
    ;;[common-cand] ::= 共通の候補数字  ;
    (setf common-cand (intersection cand-1 cand-2 :test #'=))
    (when (debug-write-p "single-linked-and-common-p")
      (format t "(single-linked-and-common-p ~s ~s)~%" ALS-A ALS-B)
      (format t "cand-1 = ~s~%" cand-1)
      (format t "cand-2 = ~s~%" cand-2)
      (format t "common-cand = ~s~%" common-cand)
      )
    (if (< (length common-cand) 2) (return-from single-linked-and-common-p nil))

    (setf result nil)
    (dolist (p common-cand)
      ;; [cells-1], [cells-2]にはリンク･ラベル[p]を含む[ALS-A], [ALS-B]それぞれのセル･アドレスのリストが入る。
      (setf cells-1 nil)
      (dolist (q (cdr ALS-A))
        (if (member p (second q) :test #'=) (push (first q) cells-1)) )

      (setf cells-2 nil)
      (dolist (q (cdr ALS-B))
        (if (member p (second q) :test #'=) (push (first q) cells-2)) )

      (setf tmp (all-same-unit-p (append cells-1 cells-2)))
      (if (identity tmp) (push p result))
      (when (debug-write-p "single-linked-and-common-p")
        (format t "dolist : p = ~s~%" p)
        (format t "cells-1 = ~s~%" cells-1)
        (format t "cells-2 = ~s~%" cells-2)
        (format t "(all-same-unit-p ~s) = ~s~%" (append cells-1 cells-2) tmp)
        (format t "result = ~s~%" result)
        )
      )

    (setf answer nil)
    (when (and (>= (length result) 1) (>= (length common-cand) 2))
      (setf tmp (set-difference common-cand result :test #'equal))
      (when (debug-write-p "single-linked-and-common-p")
        (format t "total result = ~s~%" result)
        (format t "(set-difference [common-cand] [result]) = ~s~%" tmp)
        )
      (cond
        ((null tmp)
         (setf answer nil))
        ((= (length result) 1)
         (setf answer (list result tmp)))
        (t (do-nothing)))
      )
    (return-from single-linked-and-common-p answer)))

(defun collect-candidates (lst)
"候補数字一覧を返す。
[lst] ::= (([セルアドレス] [候補数字])...) ;
[返り値] ::= ([候補数字]...) ;"
  (let (result)
    (setf result nil)
    (dolist (p lst) (setf result (append result (second p))))
    (return-from collect-candidates (sort (copy-seq (unique result)) #'<))))

(defun collect-cells (lst)
"[lst] ::= ( ([セルアドレス] [候補数字])... ) ;"
  (let (result)
    (setf result nil)
    (dolist (p lst) (push (first p) result))
    (return-from collect-cells (reverse result))))

(defun candidate-addr (lst)
"[セルアドレス]と[候補数字リスト]のリストからなるリストを受け取って候補数字ごとに
候補数字を含むセルアドレスのリストのリストを返す。返り値は整列済み。
[lst] ::= (([セルアドレス] ([候補数字]...))...) ;
[brd] ::= [盤面] ;
[返り値] ::= ( ([候補数字] [セルアドレス]...) ... ) ;
Ex. (candidate-addr '(((1 1) (5 9)) ((1 2) (5 9)) ((1 6) (8 9))))
  ==> ((5 (1 1) (1 2)) (8 (1 6)) (9 (1 1) (1 2) (1 6)))"
  (let (result tmp)
    (setf result nil)
    (dolist (p (collect-candidates lst))
      (setf tmp nil)
      (dolist (q lst)
        (when (member p (second q) :test #'=)
          (setf tmp (union tmp (list (first q)) :test #'equal))
          )
        ;;(format t "p = ~a, q = ~a, tmp = ~a~%" p q tmp)
        )
      (setf tmp (sort (copy-seq tmp) #'cell-order-p))
      (push p tmp)
      (push tmp result)
      ;;(format t "result = ~a~%" result)
      )
    (return-from candidate-addr (reverse result))))

(defun can-see-all-the-candidates-for (lst brd)
"[セルアドレス]...内のすべての[候補数字]を見ることができる([候補数字]と([セルアドレス]のリスト))
のリストを返す。
[lst] ::= ( ([候補数字] [セルアドレス]...)... ) ; [lst] is sorted by [collect-candidates].
[返り値] ::= ( ([削除可能候補] [セルアドレス]...)... ) ; so, return value is also sorted.

Ex.((1 (3 2) (3 5)) (5 (4 0) (5 0)) (7 (3 1) (3 2) (3 5)) (8 (5 0) (3 1) (3 2)) (9 (3 1) (4 0)))
  ==> ((5 (4 2) (5 1) (6 0)) (9 (4 2))) ;

( (1はr4c3,r4c6に含まれる) (5はr5c1,r6c1に含まれる) (7はr4c2,r4c3,r4c6に含まれる)
  (8はr6c1,r4c2,r4c3に含まれる) (9はr4c2,r5c1に含まれる) )
  ==> ( (r5c3,r6c2,r7c1に含まれる5はr5c1,r6c1に含まれるすべての5を見ることができる)
        (r5c3に含まれる9はr4c2,r5c1に含まれるすべての9を見ることができる) )
  ==> r5c3,r6c2,r7c1の5, r5c3の9は削除できる。"
  (let (result candidate cand house can-see cells cell-list cell row col first-only tmp)
    ;;(format t "(can-see-all-the-candidates-for ~s [brd])~%" lst)
    (setf result nil)
    (dolist (p lst)
      (setf candidate (first p))
      (setf cells (rest p))
      (setf cell-list (copy-seq cells))
      ;;(format t "~%candidate = ~a, cells = ~a~%" candidate cells)

      (setf first-only t)
      (loop
         (if (null cells) (return))
         (setf cell (pop cells))
         ;;(format t "cell = ~s~%" cell)
         (setf house (same-unit-cells cell))
         ;;(setf house (set-difference (same-unit-cells cell) (list cell) :test #'equal))
         ;;(format t "house = ~s~%" house)
         (cond
           ((identity first-only)
            (setf can-see house)
            (setf first-only nil))
           (t (setf can-see (intersection can-see house :test #'equal))))
         ;;(format t "can-see = ~s~%" can-see)
         )
      (setf can-see (set-difference can-see cell-list :test #'equal))
      ;;(format t "can-see(2) = ~s~%" can-see)

      (setf tmp nil)
      (dolist (q can-see)
        (setf row (first q) col (second q))
        (setf cand (aref brd row col))
        ;;(format t "(aref [brd] ~d ~d) = ~s~%" row col cand)
        (if (and (pure-listp cand) (member candidate cand :test #'equal)) (push q tmp))
        )

      (when (identity tmp)
        (setf tmp (sort (copy-seq tmp) #'cell-order-p))
        (push candidate tmp)
        (push tmp result)
        )
      )
    (return-from can-see-all-the-candidates-for (reverse result))))

(defun do-GB-ALS (board)
"Grid Based Almost Locked Setの実装。
[do-grid-based-almost-locked-set]の別名。"
  (let (brd info-list)
    (multiple-value-setq (brd info-list) (do-grid-based-almost-locked-set board))
    (return-from do-GB-ALS (values brd info-list))
    ) ;; end let
  ) ;; do-GB-ALS

(defun do-grid-based-almost-locked-set (board)
  "Grid Based Almost Locked Setの実装。"
  (let (brd gb-col-list gb-row-list elm-cells result-list info-list)

    (if (finished-p board) (return-from do-grid-based-almost-locked-set board))
    (setf brd (new-board board))
    (setf gb-col-list (make-array *board-size* :initial-element nil))
    (setf gb-row-list (make-array *board-size* :initial-element nil))

    ;; グリッド解析ボードを基に各候補数字に対する[gb-col-list]と[gb-row-list]を用意する。
    (let (block-cells col-grid row-grid row col)
      (setf col-grid (make-col-grid brd))
      (setf row-grid (make-row-grid brd))
      (dolist (kind '(col row))
        (case kind
          (col
           (dotimes (blk *board-size*)
             (setf block-cells (same-block-cells-for-block blk))
             (dotimes (num-in-block *board-size*)
               (setf row (first (nth num-in-block block-cells)) col (second (nth num-in-block block-cells)))
               (when (pure-listp (aref col-grid row col))
                 (push (list num-in-block (sort (aref col-grid row col) #'<)) (aref gb-col-list blk))
		 ) ;; end when
	       )   ;; end dotimes
             (setf (aref gb-col-list blk) (sort (aref gb-col-list blk) #'list-lessp))
	     ) ;; end dotimes
	   )   ;; end col
          (row
           (dotimes (blk *board-size*)
             (setf block-cells (same-block-cells-for-block blk))
             (dotimes (num-in-block *board-size*)
               (setf row (first (nth num-in-block block-cells)) col (second (nth num-in-block block-cells)))
               (when (pure-listp (aref row-grid row col))
                 (push (list num-in-block (sort (aref row-grid row col) #'<)) (aref gb-row-list blk))
		 ) ;; end when
	       )   ;; end dotimes
             (setf (aref gb-row-list blk) (sort (aref gb-row-list blk) #'list-lessp))
	     ) ;; end dotimes
	   )   ;; end row
          )    ;;end case
        )      ;;end dolist
      )	       ;;end let

    ;; [result-list]に結果を蓄積する。
    ;;
    ;; [result-list] ::= ([result-element] ...) ;
    ;; [result-element] ::= ( [kind] [candidate] [gb-cells] [contra-cells] ) ;
    ;; [kind] ::= 'col | 'row ;
    ;; [gb-cells] ::= [gb-col-cells] | [gb-row-cells] ;
    ;; [gb-col-list] ::= [col方向のGB-ALS] ; 関数[gb-col-list-to-cells]でセルアドレスに変換可。
    ;; [gb-row-list] ::= [row方向のGB-ALS] ; 関数[gb-row-list-to-cells]でセルアドレスに変換可。
    ;; [contra-cells] ::= [GB-ALSに矛盾を発生させる削除可能候補のセルアドレス] ;
    (let (contra-cells cols-and-rows tmp)
      (dolist (kind '(col row))
        (dotimes (i *board-size*)

          ;; find-grid-alsはGB-ALSのリストを返す。
          ;; (((2 (3 4)) (5 (3 4)) (7 (5 8))) ((2 (3 4)) (5 (3 4)) (8 (5 8))) ((2 (3 4)) (7 (5 8)) (8 (5 8)))) 
          ;; abobe structure is ([GB-ALS-1] [GB-ALS-2] [GB-ALS-3]) ;
          (cond
            ((eq kind 'col)
             (setf tmp (find-grid-als (aref gb-col-list i))) )
            ((eq kind 'row)
             (setf tmp (find-grid-als (aref gb-row-list i))) ) )

          (dolist (p tmp) ;; GB-ALSを構成する各セル配置に対して矛盾を引き起こすセルを探索する。
            (when (debug-write-p "do-GB-ALS") ;; 生成されるすべてのGB-ALSをチェック用に表示する。
              (print-mini (make-mini-board (gb-col-list-to-cells p) "#"))
              (cond
                ((eq kind 'col)
                 (format t "col方向のGB-ALS~%"))
                ((eq kind 'row)
                 (format t "row方向のGB-ALS~%"))
                )
              ) ;; end when
            (cond
              ((eq kind 'col)
               (multiple-value-setq (contra-cells cols-and-rows) (als-contradiction-cells brd p (1+ i) 'col))
               (if (identity contra-cells) (push (list 'col (1+ i) p contra-cells cols-and-rows) result-list))
               )
              ((eq kind 'row)
               (multiple-value-setq (contra-cells cols-and-rows) (als-contradiction-cells brd p (1+ i) 'row))
               (if (identity contra-cells) (push (list 'row (1+ i) p contra-cells cols-and-rows) result-list))
               )
              )
            ) ;; end dolist

          ) ;; end dotimes
        )   ;; end dolist
      )	    ;; end let

    ;; 同じ結果となる盤面に縮約する。
    (when (not (gb-als-show-all))
      (setf result-list (reduce-GB-ALS-list result-list))
      )
    (debug-write "do-gb-als-1" (format nil "result-list=~a~%" result-list))
    ;; result-list. for example
    ;; ( (col 7 ((1 (3 5 8)) (6 (8))) ((5 0) (3 0)) ((1 2) (1 2)))
    ;;   (row 7 ((3 (0 1 8)) (5 (0 1 8)) (8 (0 1 6 8))) ((7 8)) ((3 2))) )

    ;; [result-list]を元に結果を表示し、削除可能候補のリスト[elm-cells]を作成する。
    (let (kind candidate gb-cells mini-brd contra-cells cols-and-rows fmt cand-list)
      (setq info-list nil)
      (dolist (p result-list)
	;; [kind] ::= {col|row} ;
	;; [candidate] ::= 対象となる候補数字 ;
	;; [gb-cells] ::= 候補となるセル・アドレス(要変形) ;
	;; [contra-cells] ::= 矛盾を引き起こす候補のセル・アドレス(削除可) ;
        (setq kind          (nth 0 p))
	(setq candidate     (nth 1 p))
	(setq gb-cells      (nth 2 p))
        (setq contra-cells  (nth 3 p))
	(setq cols-and-rows (nth 4 p))
	(setf elm-cells nil)
        (dolist (q contra-cells)
	  (push (list q candidate) elm-cells) ;; "elm' is abbreviation for elimination.
	  )				      ;; end dolist
	;; elm-cells=( ((3 0) 7) ((5 0) 7) )
	;; elm-cells=( ((7 8) 7) ((3 0) 7) ( (5 0) 7) )


	;; [guess-game]用の情報収集
	;;========================================================================================
	(record-quiz-info :function-name 'do-grid-based-almost-locked-set)
	(debug-write "do-gb-als-2" (format nil "contra-cells=~a, elm-cells=~a~%" contra-cells elm-cells))
	(setq elm-cells (unique elm-cells #'equal))
	(setq cand-list nil)
	(dolist (p elm-cells)
	  (push (cannotbe-list (first p) (rest p)) cand-list)
	  ) ;; end dolist
	(setq cand-list (sort (copy-seq cand-list) #'(lambda (x y) (cell-order-p (second x) (second y)))))
	(cond
	  ((equal kind 'row)
	   (record-quiz-info
	    :explanation (format nil "候補数字[~d]に関して行方向のGB-ALSを構成しています" candidate))
	   (record-quiz-info :position (gb-row-list-to-cells gb-cells))
	   (record-quiz-info :candidate cand-list)
	   )
	  ((equal kind 'col)
	   (record-quiz-info
	    :explanation (format nil "候補数字[~d]に関して列方向のGB-ALSを構成しています" candidate))
	   (record-quiz-info :position (gb-col-list-to-cells gb-cells))
	   (record-quiz-info :candidate cand-list)
	   )
	  ) ;; end cond
	(push (list (record-quiz-info)) info-list)
	(debug-write "do-gb-als-3" (format nil "info-list=~a~%" info-list))
	(reset-record-quiz-info)
	;;========================================================================================

        (setf fmt (format nil "GB Almost Locked Set(~s#~d)" kind candidate))
        (plot-info fmt *difficulty-GB-ALS* (length fmt))
        (method-applied 'do-grid-based-almost-locked-set)

        (when (print-check)
          ;;(print-depth)
          (format t "Grid-Based Almost Locked Setにより")
          (cond
            ((and (show-color-board) (>= (color-mode) 1))
             (print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*))))
            (t (format t "[~a]" *at-mark*))
	    ) ;; end cond
          (format t "の位置から候補を削除できます。~%")
          (cond
            ((eq kind 'col)
             (setf mini-brd (make-grid-check-board brd candidate (gb-col-list-to-cells gb-cells)))
             (dolist (q contra-cells)
	       (setf (aref mini-brd (first q) (second q)) *at-mark*)
	       )
             (print-GB-ALS-message brd mini-brd contra-cells cols-and-rows candidate 'col)
             )
            ((eq kind 'row)
             (setf mini-brd (make-grid-check-board brd candidate (gb-row-list-to-cells gb-cells)))
             (dolist (q contra-cells)
	       (setf (aref mini-brd (first q) (second q)) *at-mark*)
	       )
             (print-GB-ALS-message brd mini-brd contra-cells cols-and-rows candidate 'row)
             )
            ) ;; end cond
          )   ;; end (when (print-check)
        )     ;; end dolist
      )	      ;; end let

    ;; 削除可能候補のセルアドレスのリスト[elm-cells]を元にボードから削除可能候補を削除する。
    (when (identity elm-cells)
      (setf brd (do-elimination brd (make-cannotbe-list (unique elm-cells))))
      (if (>= (explanation-level) 10) (print-board brd))
      ) ;; end when
    (return-from do-grid-based-almost-locked-set (values (clean-up-board brd) (list (reverse info-list))))
    ) ;; end let
  ) ;; end do-grid-based-almost-locked-set

(defun reduce-GB-ALS-list (gb-als-result)
"[gb-als-result]を効率的な手筋のみに縮約する。
[gb-als-result] ::= (([kind] [candidate] [gb-cells] [contra-cells] [cols-and-rows])...) ;

効率的手筋とは、共通の候補数字を削除できる場合
  ・より多くの候補数字を一括削除できる方が効率的。
      ==> 自明。
  ・2つのGB-ALSの行数と列数の2乗の和が小さい方が効率的。
      ==> 大きなGB-ALSを発見するよりコンパクトなGB-ALSを発見する方が楽。
と定義する。"
  (let (result gb-als-elm-1 gb-als-elm-2 lst len p i)
    (if (null gb-als-result) (return-from reduce-GB-ALS-list nil))
    (if (= (length gb-als-result) 1) (return-from reduce-GB-ALS-list gb-als-result))
    (setf lst (sort (copy-seq gb-als-result) #'smaller-gb-als))
    ;;(format t "reduce-GB-ALS-list:sorted = ~s~%" lst)
    (setf result nil i 0 len (length lst))
    (loop
       (catch 'junk
         (setf p (nth i lst))
         (setf gb-als-elm-1 (nth 3 p))
         ;;(format t "gb-als-elm-1 = ~s~%" gb-als-elm-1)
         (incf i)
         (if (>= i len) (return))
         (dolist (q (nthcdr i lst))
           (setf gb-als-elm-2 (nth 3 q))
           ;;(format t "gb-als-elm-2 = ~s~%" gb-als-elm-2)
           (cond
             ((purely-subsetp gb-als-elm-1 gb-als-elm-2)
              (throw 'junk nil))
             ((and
               (equal gb-als-elm-1 gb-als-elm-2)
               (efficient-GB-ALS-p q p))
              (throw 'junk nil)) )
           ) ;;end dolist
         (push p result)
         ;;(format t "result = ~s~%" result)
         ) ;;end catch
       )   ;;end loop
    (return-from reduce-GB-ALS-list result)))

(defun efficient-GB-ALS-p (gb-als-result-1 gb-als-result-2)
"[gb-als-result-1]が[gb-als-result-2]より\"効率的\"なGrid-Based Almost Locked Setの手筋か否かを返す。

効率的手筋とは、共通の候補数字を削除できる場合
  ・より多くの候補数字を一括削除できる方が効率的。
      ==> 自明。
  ・2つのGB-ALSの行数と列数の2乗の和が小さい方が効率的。
      ==> 大きなGB-ALSを発見するよりコンパクトなGB-ALSを発見する方が楽。
と定義する。共通の候補数字を削除できない場合は「効率的」と判断できないので[nil]。
削除対象候補数字が異なる場合も判断できないので[nil]を返す。定義した基準に従って判断出来た場合のみ[t]
を返す場合がある。そうでない場合はすべて[nil]。

[gb-als-result-{1|2}] ::= ([kind] [candidate] [gb-cells] [contra-cells] [cols-and-rows]) ;
[kind]                ::= 'col | 'row ;
[gb-cells]            ::= [gb-col-cells] | [gb-row-cells] ;
[gb-col-cells]        ::= [column方向のGB-ALS] ; 関数[gb-col-list-to-cells]でセルアドレスに変換可。
[gb-row-cells]        ::= [row方向のGB-ALS] ; 関数[gb-row-list-to-cells]でセルアドレスに変換可。
[contra-cells]        ::= ([GB-ALSに矛盾を発生させる削除可能候補のセルアドレス]...) ;
[cols-and-rows]       ::= ([列数] [行数]) | ([行数] [列数]) ;

[gb-als-result-{1|2} Example:

(row 8 ((0 (3 7)) (3 (3 4)) (7 (3 4 5 7))) ((8 4) (8 3) (6 4)) ((3 2) (3 2) (3 2)))
(col 8 ((2 (6 8)) (5 (1 6 7)) (8 (1 6 8))) ((8 4) (8 3) (6 4)) ((2 3) (2 3) (2 3)))
(col 8 ((2 (6 8)) (4 (1 3 6 7 8)) (5 (1 6 7)) (8 (1 6 8))) ((8 3)) ((3 4)))"
  (let (contra-cells-1 contra-cells-2 gb-als-cols-1 gb-als-rows-1 gb-als-cols-2 gb-als-rows-2 tmp)
    (setf contra-cells-1 (nth 3 gb-als-result-1))
    (setf contra-cells-2 (nth 3 gb-als-result-2))
    (if (not (intersection contra-cells-1 contra-cells-2 :test #'equal))
        (return-from efficient-GB-ALS-p nil))

    (cond
      ((> (length contra-cells-1) (length contra-cells-2))
       (return-from efficient-GB-ALS-p t))
      ((< (length contra-cells-1) (length contra-cells-2))
       (return-from efficient-GB-ALS-p nil)))

    ;; (= (length contra-cells-1) (length contra-cells-2))
    (cond
      ((eq (first gb-als-result-1) 'col)
       (setf gb-als-cols-1 (length (nth 2 gb-als-result-1)))
       (setf tmp nil)
       (dolist (p (nth 2 gb-als-result-1)) (setf tmp (union tmp (second p))))
       (setf gb-als-rows-1 (length tmp)))
      ((eq (first gb-als-result-1) 'row)
       (setf gb-als-rows-1 (length (nth 2 gb-als-result-1)))
       (setf tmp nil)
       (dolist (p (nth 2 gb-als-result-1)) (setf tmp (union tmp (second p))))
       (setf gb-als-cols-1 (length tmp))))
    (cond
      ((eq (first gb-als-result-2) 'col)
       (setf gb-als-cols-2 (length (nth 2 gb-als-result-2)))
       (setf tmp nil)
       (dolist (p (nth 2 gb-als-result-2)) (setf tmp (union tmp (second p))))
       (setf gb-als-rows-2 (length tmp)))
      ((eq (first gb-als-result-2) 'row)
       (setf gb-als-rows-2 (length (nth 2 gb-als-result-2)))
       (setf tmp nil)
       (dolist (p (nth 2 gb-als-result-2)) (setf tmp (union tmp (second p))))
       (setf gb-als-cols-2 (length tmp))))

    (cond
      ((< (+ (expt gb-als-cols-1 2) (expt gb-als-rows-1 2))
          (+ (expt gb-als-cols-2 2) (expt gb-als-rows-2 2)))
       (return-from efficient-GB-ALS-p t))
      ((> (+ (expt gb-als-cols-1 2) (expt gb-als-rows-1 2))
          (+ (expt gb-als-cols-2 2) (expt gb-als-rows-2 2)))
       (return-from efficient-GB-ALS-p nil))
      (t (return-from efficient-GB-ALS-p nil)))
    )
  )

(defun smaller-GB-ALS (x y)
"[gb-als-result]形式のリスト[x]と[y]を比較して[x]の方が小さければ[t]を返し、そうでなければ[nil]を返す。
候補数字が小さい方が小さく、候補数字が同じ場合は削除可能候補数が少ない方が小さいとする。
[gb-als-result] ::= ([kind] [candidate] [gb-cells] [contra-cells] [cols-and-rows]) ;"
  (cond
    ((< (second x) (second y)) t)
    ((> (second x) (second y)) nil)
    (t (<= (length (nth 3 x)) (length (nth 3 y))))))

(defun als-contradiction-cells (brd grid-als candidate kind)
"グリッドベース形式アドレスで表現されている[candidate]に対する[kind]方向のGB-ALS[grid-als]
に存在する候補数字[candidate]の内、GB-ALS[grid-als]に矛盾を引き起こす候補が存在するか否かを返す。
矛盾が存在すれば矛盾を引き起こすセルアドレスのリストを返す。そうでなければ[nil]を返す。
また第2の値として[kind]が['col]の場合は ([列数] [行数]) のリストを、[kind]が['row]の場合は
([行数] [列数])のリストを返す。contradictionは矛盾の意。

[grid-als]     ::= [gb-col-list] | [gb-row-list] ;
[gb-col-list]  ::= ( ([列番号] ([行番号_1]...[行番号_n]))... ) ;
[gb-row-list]  ::= ( ([行番号] ([列番号_1]...[列番号_n]))... ) ;
[candidate]    ::= [候補数字] ;
[kind]         ::= 'col | 'row ;
[返り値]       ::= ( ([行番号] [列番号]) ... ) ; 左上が0行0列となるセルアドレス。

[grid-als]の例 : ((2 (3 4)) (5 (3 5)) (7 (4 5 7)))"
  (let (result diff-addr cell-list gb-cell-list house-cells masked-cells
               contra-cell cols-and-rows est-cells c-and-r tmp)
    (setf result nil cell-list nil cols-and-rows nil)

    ;; Grid-Based ALSを構成するセルアドレスを左上が0行0列となる通常表現のセルアドレスに変換する。
    (cond
      ((eq kind 'col)
       (setf gb-cell-list (gb-col-list-to-cells grid-als)))
      ((eq kind 'row)
       (setf gb-cell-list (gb-row-list-to-cells grid-als)))
      (t (error "als-contradiction-cells:kind should be 'col or 'row.")))
    (setf gb-cell-list (sort (copy-seq gb-cell-list) #'list-lessp))

    ;;(when (equal gb-cell-list '((0 0) (0 3) (2 8) (5 0) (5 8) (6 3) (6 8)))
    ;;  (format t "*** debug switch on!~%")
    ;;  (add-debug-point "als-contradiction-cells-1")
    ;;  (add-debug-point "als-contradiction-cells-2")
    ;;  (print-mini (make-mini-board gb-cell-list "#"))
    ;;  (format t "gb-cell-list = ~s~%" gb-cell-list)
    ;;  )

    ;; 候補数字[candidate]を含むセルアドレスのリストを得る(確定値は含まない)。
    (setf cell-list (reverse (collect-candidate-address-for brd candidate)))

    ;; [candidate]を候補数字として含むセルであってGB-ALSであるセル[grid-cell-list]の要素でないセルアドレス。
    ;; =GB-ALS以外の候補数字のセルアドレス。
    (setf diff-addr (set-difference cell-list gb-cell-list :test #'equal))

    ;; セル[p]に候補数字[candidate]を仮定した場合にGB-ALSが矛盾に至らないかを調べる。
    (dolist (p diff-addr)
      (setf house-cells (same-unit-cells p))
      (setf masked-cells (set-difference gb-cell-list house-cells :test #'equal))
      (setf c-and-r (count-cols-and-rows masked-cells))
      (debug-write "c-and-r" (format nil "~%c-and-r = ~s~%" c-and-r))
      (if (null c-and-r) (return)) ;; 2023-12-06

      (when (debug-write-p "als-contradiction-cells-1")
        (print-normal brd)
        (print-cells cell-list "*")
        (format t "cell-list = ~s~%" cell-list)
        (print-cells diff-addr "*")
        (format t "diff-addr = ~s~%" diff-addr)
        (print-cells house-cells "$")
        (format t "(same-unit-cells ~s) = ~s~%" p house-cells)
        (print-cells masked-cells "*")
        (format t "masked-cells = ~s~%" masked-cells)
        (format t "(count-cols-and-rows [masked-cells]) = ~s~%~%" c-and-r)
        )

      (setf contra-cell nil)
      (cond
        ((and (eq kind 'col) (< (first c-and-r) (second c-and-r)))
         (push c-and-r cols-and-rows)
         (setf contra-cell p)
         (push contra-cell result))
        ((and (eq kind 'row) (> (first c-and-r) (second c-and-r)))
         (push c-and-r cols-and-rows)
         (setf contra-cell p)
         (push contra-cell result)))

      ;; 行・列に確定値が発生することによる副作用で矛盾が発生するケースの処理。
      (setf est-cells (established-p (set-difference diff-addr house-cells :test #'equal) kind))
      (when (identity est-cells)
        (setf tmp masked-cells)
        (dolist (q est-cells) (setf tmp (set-difference tmp (same-unit-cells q) :test #'equal)))
        (setf c-and-r (count-cols-and-rows tmp))
        (debug-write "c-and-r" (format nil "~%c-and-r = ~s~%" c-and-r))
        (if (null c-and-r) (return)) ;; 2023-12-06

        (when (debug-write-p "als-contradiction-cells-2")
          (print-cells tmp "*")
          (format t "~d行 x ~d列~%" (first c-and-r) (second c-and-r))
          ;;(reset-debug-point)
          ) ;;end when

        (cond
          ((and (eq kind 'col) (< (first c-and-r) (second c-and-r)))
           (push (list 'sashimi c-and-r est-cells) cols-and-rows)
           (push p result))
          ((and (eq kind 'row) (> (first c-and-r) (second c-and-r)))
           (push (list 'sashimi c-and-r est-cells) cols-and-rows)
           (push p result))
          ) ;;end cond
        ) ;;end when
      ) ;;end dolist

    (return-from als-contradiction-cells (values result cols-and-rows))))

(defun established-p (cells kind)
"特定候補数字のセルアドレスのリスト[cells]に含まれる候補数字のうち[kind]方向でひとつに確定している場所がないかチェックする。確定値が発生している行、または列があれば、そのセルアドレスのリストを返す。そうでなければ[nil]を返す。"
  (let (lines result)
    (setf lines (make-array *board-size* :initial-element nil))
    (cond
      ((eq kind 'col)
       (dolist (p cells) (push p (aref lines (second p)))))
      ((eq kind 'row)
       (dolist (p cells) (push p (aref lines (first p)))))
      (t (error "can't happen at established-p.")))
    (setf result nil)
    (dotimes (i *board-size*)
      (if (= (length (aref lines i)) 1) (setf result (append result (aref lines i))))
      )
    (return-from established-p result)))

(defun collect-candidate-address-for (brd candidate)
"候補数字[candidate]を含むセルアドレスのリストを返す。"
  (let (cand result)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf cand (aref brd i j))
        (when (and (pure-listp cand) (member candidate cand :test #'=))
          (push (list i j) result)
          )
        )
      )
    (return-from collect-candidate-address-for result)))

(defun count-cols-and-rows (cell-list)
"通常形式のセルアドレスのリスト[cell-list]に含まれるセルアドレスの行数と列数をリストにした値を返す。"
  (let (cols rows)
    (if (null cell-list) (return-from count-cols-and-rows nil))
    (setf cols nil rows nil)
    (dolist (p cell-list)
      (push (first p) rows)
      (push (second p) cols)
      )
    (setf rows (unique rows))
    (setf cols (unique cols))
    (return-from count-cols-and-rows (list (length rows) (length cols)))))

(defun make-grid-check-board (brd candidate als-list)
"候補数字[candidate]を含むセルをミニボード・サイズで表示する。[candidate]が確定値であるセルには
[candidate]を、候補数字のひとつとして含まれるセルには候補数字が2個なら[=]を3個以上なら[+]を、
[als-list]で指定されたセルには[#]を設定する。[als-list]には[candidate]を含むセルのうちALSを構
成するセルアドレスが含まれている。

[als-list] ::= ( [セルアドレス]... ) ;
[返り値] ::= [board型データ] ;"
  (let (mini-grid-brd element)
    (setf mini-grid-brd (make-array (list *board-size* *board-size*) :initial-element nil))
    ;;(format t "~%*** (make-grid-check-board [brd] ~d ~s)~%" candidate als-list)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf element (aref brd i j))
        (if (integerp element) (setf element (list element)))
        ;;(format t "(aref [brd] ~d ~d) = ~s~%" i j element)
        (cond
          ((equal element (list candidate))
           (setf (aref mini-grid-brd i j) candidate))
          ((member (list i j) als-list :test #'equal)
           (setf (aref mini-grid-brd i j) *sharp-mark*))
          ((member candidate element :test #'=)
           ;;(setf (aref mini-grid-brd i j) *dollar-mark*))
           (setf (aref mini-grid-brd i j) element))
          (t (do-nothing))
	  ) ;; end cond
	) ;; end dotimes
      ) ;; end dotimes
    (return-from make-grid-check-board mini-grid-brd)
    ) ;; end let
  ) ;; end make-grid-check-board

(defun gb-col-list-to-cells (gb-col-list)
  "Grid(col)形式のセルアドレス表記のリストを受け取って、通常のセルアドレス表記のリストに変換する。

[gb-col-list] ::= ( ([列番号] ([行番号_1]...[行番号_n]))... ) ;
[返り値] ::= ( ([行番号_1] [列番号]) ([行番号_2] [列番号]) ... ) ;"
  (let (result)
    (setf result nil)
    (dolist (p gb-col-list)
      (dolist (q (second p))
        (push (list q (first p)) result)
	) ;; end dolist
      )	  ;; end dolist
    (return-from gb-col-list-to-cells (sort result #'cell-order-p))
    ) ;; end let
  ) ;; end gb-col-list-to-cells

(defun gb-row-list-to-cells (gb-row-list)
"Grid(row)形式のセルアドレス表記のリストを受け取って、通常のセルアドレス表記のリストに変換する。

[gb-row-list] ::= ( ([行番号] ([列番号_1]...[列番号_n]))... ) ;
[返り値] ::= ( ([行番号] [列番号_1]) ([行番号] [列番号_2]) ... ) ;"
  (let (result)
    (setf result nil)
    (dolist (p gb-row-list)
      (dolist (q (second p))
        (push (list (first p) q) result)
	) ;; end dolist
      ) ;; end dolist
    (return-from gb-row-list-to-cells (sort result #'cell-order-p))
    ) ;; end let
  ) ;; end gbrow-list-to-cells

(defun find-grid-als (lst)
"Grid Based Almost Locked SetのALSを探す。発見した場合はALSのリストを返す。
発見できなかった場合は[nil]を返す。

[lst]  ::= ( ([col] ([rows]))... ) | ( ([row] ([cols]))... ) ;
[col]  ::= 0...8 ; 9x9サイズのナンプレの場合。
[cols] ::= [col]... ;
[row]  ::= 0...8 ; 9x9サイズのナンプレの場合。
[rows] ::= [row]... ;
[返り値] ::=( ([col] ([rows]))... ) | ( ([row] ([cols]))... ) | nil ;
Ex.( ((2 (3 4)) (5 (3 4)) (7 (5 8))) ((2 (3 4)) (5 (3 4)) (8 (5 8))) ((2 (3 4)) (7 (5 8)) (8 (5 8))) )"
  (let (result len comb-list)
    (if (null lst) (return-from find-grid-als nil))
    (setf result nil)
    (setf len (length lst))
    (do
     ((i 2 (incf i)))
     ((> i len))
      (setf comb-list (combination lst i))
      (dolist (p comb-list)
        (when (almost-locked-set-p (mapcar #'second p))
          (push (sort p #'list-lessp) result)
          )
        )
      ) ;;end do
    (return-from find-grid-als result)
    ) ;; end let
  ) ;; end find-grid-als

(defun print-GB-ALS-message (board mini-brd contra-cells cols-and-rows candidate kind)
"ミニボード[mini-brd]に記録されているGB-ALS盤面の解説を表示する。
行・列に確定値が発生することによる副作用で矛盾が発生していた場合は[cols-and-rows]には[sashimi-case],
そうでない場合は[normal-case]のデータ形式となる。

[cols-and-rows] ::= ({[sashimi-case] | [normal-case]}...) ;
[sashimi-case]  ::= ( 'sashimi [c-and-r] [est-cells] ) ;
[normal-case]   ::= [c-and-r] ;
[c-and-r]       ::= ([行数] [列数]) ;
[est-cells]     ::= ([セルアドレス]...) ;"
  (let (brd kind-name c-and-r est-cells len len2 cell)
    ;;(format t "*** cols-and-rows = ~s~%" cols-and-rows)
    (setf brd (new-board board))

    (debug-write "print-GB-ALS-message" (format nil "(color-mode)=~d~%~s" (color-mode) mini-brd))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf cell (aref mini-brd i j))
        (debug-write "print-GB-ALS-message" (format nil "(~d,~d)=~a" i j cell))
        (cond
          ;;((equal cell *dollar-mark*)
          ;; (setf brd (set-colored-cell brd (list i j) 'yellow)))
          ((equal cell *sharp-mark*)
           (setf brd (set-colored-cell brd (list i j) 'blue))
           (debug-write "print-GB-ALS-message" (format nil "candidate=~a~%~a" candidate brd))
           )
          ((equal cell *at-mark*)
           (setf brd (set-colored-candidate brd (list i j) candidate '*elimination-color*))
           )
          (t
           (do-nothing)
           )
          ) ;; end cond
        ) ;; end dotimes
      ) ;; end dotimes

    (cond
      ((eq kind 'col)
       (setf kind-name "列"))
      ((eq kind 'row)
       (setf kind-name "行"))
      (t (error "can't happend at print-GB-ALS-message.")))

    (cond
      ((and (show-color-board) (>= (color-mode) 1))
       (print-colored-string 'blue (format nil "[~a]" (short-color-name 'blue))))
      (t (format t "[~a]" *sharp-mark*)))
    (format t "は[~d]に関して~a方向のGrid-Based ALSを構成しています。~%" candidate kind-name)

    (setf len (length contra-cells))
    (dotimes (i len)
      (cond
        ((show-color-board)
         (print-colored-string 'red (format nil "~a" (cell-addr (nth i contra-cells))))
         (format t "に[~d]が存在すると" candidate))
        (t (format t "~aの[~a]に[~d]が存在すると" (cell-addr (nth i contra-cells)) *at-mark* candidate))
        ) ;; end cond

      (cond
        ((eq (first (nth i cols-and-rows)) 'sashimi)
         (setf c-and-r (nth 1 (nth i cols-and-rows)))
         (setf est-cells (nth 2 (nth i cols-and-rows)))
         )
        (t
         (setf c-and-r (nth i cols-and-rows))
         (setf est-cells nil)
         )
        ) ;; end cond
                              
      (when (identity est-cells)
        (setf len2 (length est-cells))
        (dotimes (j len2)
          (setf cell (nth j est-cells))
          (setf brd (set-colored-cell brd cell 'yellow))
          (cond
            ((show-color-board)
             (print-colored-string 'yellow (format nil "~a" (cell-addr cell))))
            (t (format t "~a" (cell-addr cell))))
          (setf (aref mini-brd (first cell) (second cell)) *dollar-mark*)
          (if (< j (1- len2)) (format t ","))
          )
        (cond
          ((show-color-board)
           (format t "が~a内での確定値となり" kind-name))
          (t (format t "の[~a]が~a内での確定値となり" *dollar-mark* kind-name)))
        ) ;;end when
      (cond
        ((eq kind 'col)
         (format t "GB-ALSの~d列のうち~d行にしか[~d]が存在できないので矛盾です。~%"
                 (second c-and-r) (first c-and-r) candidate))
        ((eq kind 'row)
         (format t "GB-ALSの~d行のうち~d列にしか[~d]が存在できないので矛盾です。~%"
                 (first c-and-r) (second c-and-r) candidate))
        (t (error "can't happen at print-GB-ALS-message(2)."))
        ) ;; end cond
      ;;) ;; end dotimes
      (format t "  ==> ")
      (dotimes (i len)
        (cond
          ((show-color-board)
           (print-colored-string 'red (format nil "~a" (cell-addr (nth i contra-cells)))))
          (t (format t "~a" (cell-addr (nth i contra-cells)))))
        (if (< i (1- len)) (format t ",")))
      (format t "~a~d~%" *not-equal-mark* candidate)
      ) ;; end dotimes
    (cond
      ((and (show-color-board) (>= (color-mode) 1))
       (print-normal brd))
      (t (print-mini mini-brd)))
    (return-from print-GB-ALS-message t)))

;;
;; 2024-01-18 無駄な処理を行っていたので修正。
;;
(defun do-fundamental (board)
"基本手筋の実装。

1..[*board-size*]の各数字について順に
各数字が存在する可能性のあるセルの位置を調べ、それが
  ・ブロック内で唯一なら確定。
  ・行内で唯一なら確定。
  ・列内で唯一なら確定。

hidden singlesとも呼ばれる。"
  (let (brd-1 info)
    (setf info nil)
    ;;(setq info-list nil)
    (setf brd-1 (new-board board))
    (multiple-value-setq (brd-1 info) (do-obvious brd-1)) ;; [info]は返していないので常に[nil]。
    (multiple-value-setq (brd-1 info) (do-fundamental-sub brd-1))
    ;;(if info (push info info-list))
    ;;(return-from do-fundamental (values brd-1 info-list))
    (return-from do-fundamental (values brd-1 (list info)))
    ) ;; end let
  ) ;; end do-fundamental

(defun do-fundamental-sub (board)
  (let (check-brd brd cells cell info-list info result row col)
    (setf brd (new-board board))
    (setf info-list nil)
    (dolist (num *np-digit*)
      (block next-dolist
        (setf info nil)
        (setf check-brd (make-check-board num brd))
        (if (null-board-p check-brd) (return-from next-dolist nil))

        (setf cells (get-all-live-cells check-brd))
        (loop
          (setf cell (pop cells))
          (if (null cell) (return))

          (setf row (first cell) col (second cell))
          (setf result nil)
          (when (listp (aref brd row col)) ;; セルが確定値ならチェックしない。
            (multiple-value-setq (result info) (check-unique check-brd row col num))
            )
          (when (and (debug-write-p "do-fundamental") (listp (aref brd row col)))
            (format t "他に~dの可能性があるのは~aのいずれか。" num cells)
            (format t "~aの~dは行・列・ブロックの\*いずれか\*で唯一の~dか？~%" cell num num)
            (print-normal brd)
            (format t "~a~%" check-brd)
            (format t "check-uniqueの結果、result=~d info=~a~%" result info)
            (print-check-board check-brd brd)
            )
          (when result
            (if info (push info info-list))
            (setf brd (print-fundamental brd check-brd row col num))
            (setf check-brd (del-all-candidate-in-group check-brd row col))
            (setf cells (set-difference cells (same-house-cells cell) :test #'equal))
            ) ;; end when
          )   ;; end loop
        )     ;; end block next-dolist
      )       ;; end dolist
    (debug-write "do-fundamental" (format nil "info-list=~a" info-list))
    (return-from do-fundamental-sub (values brd info-list))
    ) ;; end let
  )

(defun print-fundamental (board check-brd i j num)
  (let (color-brd brd cand cells)
    (setf color-brd (new-board board))
    (setf brd (new-board board))
    (when (and (aref check-brd i j) (listp (aref brd i j)))
      (setf (aref check-brd i j) *sharp-mark*) ;; 2011/06/29
      ;;(setf color-brd (copy-board brd color-brd))
      (setf color-brd (new-board brd))
      (setf cand (aref brd i j)) ;; candidate
      ;; 確定値となる候補(i行j列のnum)を緑で彩色する。
      (setf color-brd (set-colored-candidate color-brd (list i j) num 'green))
      ;; 確定値となる候補と同一セル内の他の候補数字を赤で彩色する。
      (dolist (p (set-difference cand (list num) :test #'equal))
        (setf color-brd (set-colored-candidate color-brd (list i j) p '*elimination-color*))
        )
      ;; 確定値となるセルのハウス内に存在する,確定値と同じ値の候補数字を赤で彩色する。
      (setf cells (set-difference (same-house-cells (list i j)) (list (list i j)) :test #'equal))
      (dolist (cell cells)
        (setf cand (aref brd (first cell) (second cell)))
        (when (and (pure-listp cand) (member num cand))
          (setf color-brd (set-colored-candidate color-brd cell num '*elimination-color*))
          )
        )
      (when (print-check)
        (cond
          ((show-color-board)
           (debug-write "print-fundamental" (format nil "color-brd=~a" color-brd))
           (print-normal color-brd))
          (t (print-check-board check-brd brd)))
        )
      (plot-info "基本手筋" *difficulty-fundamental* 8)
      (method-applied 'do-fundamental)
      (setf (aref brd i j) num)
      (if (trim-every-time) (setf brd (do-trim-group brd i j)))
      (if (and (print-normal) (>= (explanation-level) 10)) (print-normal brd))
      ) ;; end when
    (return-from print-fundamental brd)
    )
  )

;; [exec系]は使っていない。
(defun exec-fundamental (board)
  (let (brd)
    (if (null (easy-check board)) (return-from exec-fundamental board))
    (setf brd (new-board board))        ;make room.
    (loop
       (setf brd (do-fundamental brd))
       (if (equal-board-p brd board) (return))
       (setf board (new-board brd)))
    (return-from exec-fundamental brd)))

(defun make-check-board (num board)
"ボード[board]内で数字[num]を置ける可能性がある位置だけに[t]を
不可能な場所には[nil]を書き込んだチェックボードを作成して返す。"
  (let (check-brd tmp)
    (setf check-brd (make-null-check-board)) ;; 最初はすべて[nil]
    (dotimes (i *board-size*) ;; 確定値でないセルは、取り敢えず[t]。
      (dotimes (j *board-size*)
        (if (not (integerp (aref board i j))) (setf (aref check-brd i j) t))
        )                     ;; end dotimes
      )                       ;; end dotimes
    (dotimes (i *board-size*) ;; 各数字が存在し得ない位置は[nil]に書き換える。
      (dotimes (j *board-size*) ;; [t]のセルだけが可能性のあるセル。
        (setf tmp (aref board i j))
        (cond ;; 刈り込み済みである前提。
          ((and (listp tmp) (not (member num tmp))) ;; 確定値ではないが[num]は候補数字として残っていない。
           (setf (aref check-brd i j) nil))
          ((and (integerp tmp) (= tmp num)) ;; 確定値が[num]
           ;; 指定されたi行j列を含むハウス内の全セルを[nil]に書き換える。
           (setf check-brd (del-all-candidate-in-group check-brd i j)))
          ) ;; end cond
        )   ;; end dotimes
      )     ;; end dotimes
    (return-from make-check-board check-brd)
    ) ;; end let
  )

(defun make-null-check-board ()
  (let (check-brd)
    (setf check-brd (make-array (list *board-size* *board-size*) :initial-element nil))
    (return-from make-null-check-board check-brd)))
    
(defun print-check-board (check-brd brd)
"チェックボードと本来のボードを合成して分かりやすい形でチェックボードを出力する。"
  (let (p tmp)
    (setf p (new-board check-brd))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf tmp (aref brd i j))
        (cond
          ((and (integerp tmp) (plusp tmp))
           (setf (aref p i j) tmp))
          ((stringp (aref check-brd i j))
           (setf (aref p i j) (aref check-brd i j)))
          ((and (integerp tmp) (zerop tmp))
           (setf (aref p i j) 0))
          ((aref check-brd i j)
           (setf (aref p i j) "*"))
          (t (setf (aref p i j) "-")))))
    (print-mini p)))

(defun del-candidate-in-group (check-brd i j)
"指定されたi行j列が属するグループのセルを[nil]に書き換えたチェックボードを返す。"
  (setf check-brd (del-all-candidate-in-group check-brd i j))
  (setf (aref check-brd i j) t)
  (return-from del-candidate-in-group check-brd))

(defun del-all-candidate-in-group (check-brd i j)
"指定されたi行j列に関するグループ内の全セルを[nil]に書き換えたチェックボードを返す。"
  (setf check-brd (del-all-candidate-in-block (block-num i j) check-brd))
  (setf check-brd (del-all-candidate-in-row i check-brd))
  (setf check-brd (del-all-candidate-in-col j check-brd))
  (return-from del-all-candidate-in-group check-brd))

(defun del-all-candidate-in-block (blk-num check-brd)
"指定されたブロックを[nil]に書き換えたチェックボードを返す。"
  (let (row col)
    (setf row (block-base-row blk-num)) ;; row-base
    (setf col (block-base-col blk-num)) ;; col-base
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (setf (aref check-brd (+ row i) (+ col j)) nil)))
    (return-from del-all-candidate-in-block check-brd)))

(defun del-all-candidate-in-row (row check-brd)
"指定された行を[nil]に書き換えたチェックボードを返す。"
  (dotimes (j *board-size*) (setf (aref check-brd row j) nil))
  (return-from del-all-candidate-in-row check-brd))

(defun del-all-candidate-in-col (col check-brd)
"指定された列を[nil]に書き換えたチェックボードを返す。"
  (dotimes (i *board-size*) (setf (aref check-brd i col) nil))
  (return-from del-all-candidate-in-col check-brd))

(defun get-all-live-cells (check-brd)
"[check-brd]内の全ての生きているセル(値が[t]であるセル)のアドレスのリストを返す。"
  (let (cells)
    (setf cells nil)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (if (aref check-brd i j) (push (list i j) cells))
        ) ;; end dotimes
      )   ;; end dotimes
    (return-from get-all-live-cells (reverse cells))
    )
  )

(defun check-unique (check-brd p q num)
"[p]行[q]列の[num]がブロック/行/列のいずれかで唯一の[num]かを調べて返す。

(make-check-board num brd)が作成したチェックボード[check-brd]を調べて
p行q列の値がその属するブロック／行／列のいずれかで唯一の[t]かどうかを返す。
[num]にはmake-check-boardで使用した[num]を与える。

[i]行[j]列で[num]が唯一のあり得る候補数字なら
  ・[i]行全体で[num]が唯一の[num]。
  ・[j]行全体で[num]が唯一の[num]。
  ・[i]行[j]列が含まれるブロックで[num]が唯一の[num]。"
  (let (row col blk-num count result info pos unit-cells)
    (setf blk-num (block-num p q))
    (setf row (block-base-row blk-num)) ;; row-base ブロックの左上行
    (setf col (block-base-col blk-num)) ;; col-base ブロックの左上列
    (setf result nil)
    (setf info nil)

    ;; --- 2024-01-28
    (setf count 0)
    (setf pos nil)
    (setf unit-cells (same-unit-cells (list p q))) ;; [p]行[q]列のセルが属するセル・アドレスのリスト。
    (dolist (cell unit-cells) ;; check for house.
      (when (aref check-brd (first cell) (second cell))
        (setf pos cell)
        (incf count)
        ) ;; end when
      ) ;; end dolist
    (when (= count 1) ;; then [pos] has it.
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (format t "基本手筋です。")
        (format t "[~d]は[r~dc~d]が属するハウスでは" num (1+ (first pos)) (1+ (second pos)))
        (cond
          ((show-color-board)
           (print-colored-string 'green (format nil "[~a]" (short-color-name 'green))))
          (t (format t "[~a]" *sharp-mark*)))
        (format t "の位置にしか置けません。~%")
        )
      (setf result t)
      (debug-write "check-unique" (format nil "行=~d, 列=~d, \[ハウス\]info=~a~%" p q info))
      )
    ;; --- 2024-01-29

    (setf count 0)
    (setf pos nil)
    (dotimes (i *block-size*)           ;;check for block.
      (dotimes (j *block-size*)
        (when (aref check-brd (+ row i) (+ col j))
          (setf pos (list (+ row i) (+ col j))) ;; 2024-01-17
          (incf count)
          ) ;; end when
        ) ;; end dotimes
      ) ;; end dotimes
    (when (= count 1) ;; then [pos] has it.
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (format t "基本手筋です。")
        (format t "[~d]はブロック~dでは" num (1+ blk-num))
        (cond
          ((show-color-board)
           (print-colored-string 'green (format nil "[~a]" (short-color-name 'green))))
          (t (format t "[~a]" *sharp-mark*)))
        (format t "の位置にしか置けません。~%")
        )
      (setf result t)
      (record-quiz-info :function-name 'do-fundamental)
      (record-quiz-info :explanation (format nil "ブロック内で唯一の候補数字"))
      (record-quiz-info :position (list 'block blk-num))
      (record-quiz-info :candidate (list (list 'mustbe pos num)))
      (push (record-quiz-info) info)
      (reset-record-quiz-info)
      ;;(push (list 'do-fundamental 'unique-candidate (list 'block blk-num)
	;;	  (list 'mustbe pos num)) info)
      (debug-write "check-unique" (format nil "行=~d, 列=~d, \[ブロック\]info=~a~%" p q info))
      )

    (setf count 0)
    (setf pos nil)
    (dotimes (j *board-size*) ;;check for row.
      (when (aref check-brd p j) ;; [p]行の0列から[*board-size*]列までの[check-board]を調べる。
        (incf count)
        (setf pos j)
        )
      ) ;; end dotimes
    (when (= count 1)
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (format t "基本手筋です。")
        (format t "[~d]は~d行目では" num (1+ p))
        (cond
          ((show-color-board)
           (print-colored-string 'green (format nil "[~a]" (short-color-name 'green))))
          (t (format t "[~a]" *sharp-mark*)))
        (format t "の位置にしか置けません。~%")
        ) ;; end when
      (record-quiz-info :function-name 'do-fundamental)
      (record-quiz-info :explanation (format nil "行内で唯一の候補数字"))
      (record-quiz-info :position (list 'row p))
      (record-quiz-info :candidate (list (list 'mustbe (list p pos) num)))
      (push (record-quiz-info) info)
      (reset-record-quiz-info)
      ;;(push (list 'do-fundamental 'unique-candidate (list 'row p) (list 'mustbe (list p pos) num)) info)
      (debug-write "check-unique" (format nil "行=~d, 列=~d, \[行\]info=~a~%" p q info))
      (setf result t)
      ) ;; end when

    (setf count 0)
    (setf pos nil)
    (dotimes (i *board-size*)           ;check for col.
      (when (aref check-brd i q)
        (incf count)
        (setf pos i)
        )
      )
    (when (= count 1)
      (when (>= (mod (explanation-level) 10) 1)
        ;;(print-depth)
        (format t "基本手筋です。")
        (format t "[~d]は~d列目では" num (1+ q))
        (cond
          ((show-color-board)
           (print-colored-string 'green (format nil "[~a]" (short-color-name 'green))))
          (t (format t "[~a]" *sharp-mark*)))
        (format t "の位置にしか置けません。~%")
        ) ;; end when
      (record-quiz-info :function-name 'do-fundamental)
      (record-quiz-info :explanation (format nil "列内で唯一の候補数字"))
      (record-quiz-info :position (list 'col q))
      (record-quiz-info :candidate (list (list 'mustbe (list pos q) num)))
      (push (record-quiz-info) info)
      (reset-record-quiz-info)
      ;;(push (list 'do-fundamental 'unique-candidate (list 'col q) (list 'mustbe (list pos q) num)) info)
      (debug-write "check-unique" (format nil "行=~d, 列=~d, \[列\]info=~a~%" p q info))
      (setf result t) )

    (when (and (identity result) (show-color-board) (>= (mod (explanation-level) 10) 1))
      ;;(tabs (depth))
      (format t "  ==> ")
      (print-colored-string '*elimination-color*
			    (format nil "[~a]" (short-color-name '*elimination-color*)))
      ;;(print-colored-string 'red (format nil "[~a]" (short-color-name '*elimination-color*)))
      (format t "の位置から候補を削除できます。~%")
      )

    (return-from check-unique (values result info))
    ) ;; end let
  ) ;; end check-unique

(defun collect-decided-in-row (row board)
"指定された行内の確定値のリストを返す。"
  (let (lst tmp)
    (setf lst nil)
    (dotimes (j *board-size*)
      (setf tmp (aref board row j))
      (if (integerp tmp) (push tmp lst)))
    (return-from collect-decided-in-row lst)))

(defun collect-decided-in-col (col board)
"指定された列内の確定値のリストを返す。"
  (let (lst tmp)
    (setf lst nil)
    (dotimes (i *board-size*)
      (setf tmp (aref board i col))
      (if (integerp tmp) (push tmp lst)))
    (return-from collect-decided-in-col lst)))

(defun collect-decided-in-block (blk-num board)
"指定されたブロック内の確定値のリストを返す。"
  (let (row col lst tmp)
    (setf lst nil)
    (setf row (block-base-row blk-num)) ;; row-base
    (setf col (block-base-col blk-num)) ;; col-base
    (dotimes (i *block-size*)
      (dotimes (j *block-size*)
        (setf tmp (aref board (+ row i) (+ col j)))
        (if (integerp tmp) (push tmp lst))))
    (return-from collect-decided-in-block lst)))

(defun clean-up-board (board)
"ボード[board]を「クリーン」にする。"
  (let (brd)
    (setf brd (new-board board))
    (setf brd (do-trim brd))
    (setf brd (do-obvious brd))
    (if (not (equal-board-p brd board)) (setf brd (do-trim brd)))
    (return-from clean-up-board brd)))

(defun collect-decided-in-board (brd)
"帳尻合わせ用。"
  (let (cell)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf cell (aref brd i j))
        (if (and (pure-listp cell) (= (length cell) 1)) (setf (aref brd i j) (first cell)))))
    (return-from collect-decided-in-board brd)))

(defun new-board (board)
"配列は参照渡しなので値渡しとなるようにデータの複製を作って返す。"
  (let (tmp n)
    (setf n (board-size board))
    (setf tmp (make-array (list n n) :initial-element nil))
    (return-from new-board (copy-board board tmp)))
  )

(defun copy-board (from-brd to-brd)
"ボード[from-brd]の要素全てをボード[board]にコピーする。"
  (let (n)
    (setf n (board-size from-brd))
    (dotimes (i n)
      (dotimes (j n)
        (setf (aref to-brd i j) (aref from-brd i j))))
    (return-from copy-board to-brd)))

(defun board-p (board)
"ボードの条件を満たしているかをチェックして結果を返す。"
  (let (lst)
    (if (not (arrayp board)) (return-from board-p nil))
    (setf lst (array-dimensions board))
    (return-from board-p (and (= (length lst) 2) (= (first lst) (second lst))))))

(defun equal-board-p (brd-1 brd-2)
"ボードを表す[brd-1]と[brd-2]の「内容」が等しいか判定する。
セルの内容が候補リストの場合、処理系によっては内容が同じでも順序が異なる場合がある。
そのため (equal (aref brd-1 i j) (aref brd-2 i j)) で判定すると失敗する。"
  (let (p q)
;   (if (not (and (arrayp brd-1) (arrayp brd-2)))
    (if (not (and (board-p brd-1) (board-p brd-2)))
        (return-from equal-board-p nil))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf p (aref brd-1 i j))
        (setf q (aref brd-2 i j))
        (cond
          ((and (integerp p) (integerp q))
           (if (/= p q) (return-from equal-board-p nil)))
          ((and (integerp p) (listp q))
           (return-from equal-board-p nil))
          ((and (listp p) (integerp q))
           (return-from equal-board-p nil))
          ((and (listp p) (listp q))
           (if (< (length p) (length q)) (rotatef p q))
           (if (set-difference p q) (return-from equal-board-p nil)))
          ((not (equal p q))
           (return-from equal-board-p nil)))))
    (return-from equal-board-p t)))

(defun null-board-p (brd)
"ボード[brd]の内容が全て[nil]なら[t]、そうでないなら[nil]を返す。"
  (dotimes (i *board-size*)
    (dotimes (j *board-size*)
      (if (aref brd i j) (return-from null-board-p nil))))
  (return-from null-board-p t))

(defun next-possibility (board)
"最初の未確定欄の候補を (行番号 列番号 候補のリスト) という形式で返す。"
  (let ((lst nil))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf lst (aref board i j))
        (when (pure-listp lst)
          (return-from next-possibility (list i j lst)))))
    (return-from next-possibility nil)))
  
(defun explanation-level (&optional (level nil))
"[0]=解法手順出力なし。[1]=解説のみ。[2]=全解説。[+(解説レベル)x10]=各ボード出力あり。"
  (cond
    ((null level) *explanation-level*)
    ((integerp level) (setf *explanation-level* level))
    (t nil)))

(defun debug-write (str msg)
"*debug-point*に[str]が登録されている場合のみメッセージ[msg]を出力する。
*debug-point*に["*"]が登録されている場合は常にメッセージ[msg]を出力する。"
  (cond
    ((eq str t) ;; [str]が[t]なら常にメッセージが表示される。
     (debug-write-sub str msg)
     )
    ((and ;; [str]が[*debug-point*]に登録された文字列のどれかと一致すればメッセージを表示する。
      (stringp str)
      (member str *debug-point* :test #'string=)
      )
     (debug-write-sub str msg) )
    ((and ;; [*debug-point*]に["*"]が登録されていれば全てのdebug-writeのメッセージを表示する。
      (stringp str)
      (member "*" *debug-point* :test #'string=)
      )
     (debug-write-sub str msg)
     )
    ) ;; end cond
  ) ;; end debug-write

(defun debug-write-sub (str msg)
  ;;(print-depth)
  ;; CLISPでは[:](コロン)の直後に改行される。SBCLではされない。
  ;;(debug-write "do-coloring-5" (format nil "cells = ~a~%" cells))
  ;;
  ;; CLISP
  ;; [83]> (debug-write "do-coloring-5" (format nil "cells-added=~a~%" '((2 3))))
  ;; 0:0> do-coloring-5:
  ;; cells-added=((2 3))
  ;; t
  ;;
  ;; SBCL
  ;; [84]> (debug-write "do-coloring-5" (format nil "cells-added=~a" '((2 3))))
  ;; 0:0> do-coloring-5:cells-added=((2 3))
  ;; t
  ;;
  ;; (format t "~a:~a" str msg)
  ;;
  ;; 仕方がないので、こちらで#\NewLineを入れて、呼び出し側では入れないように変更した。
  ;;
  (format t "~a:~a~%" str msg)
  (finish-output)
  (return-from debug-write-sub t))

(defun print-list (lst)
"SBCLのリスト出力が不正となる場合があるのでバグ回避のために作成した関数。
関数[print-ALS-rule-1]内のコメントを参照。"
  (let (len tmp)
    (cond
      ((null lst)
       (write lst :stream nil :escape nil))
      ((atom lst)
       (write lst :stream nil :escape nil))
      ((listp lst)
       (write #\( :stream nil :escape nil)
       (setf len (length lst))
       (dotimes (i len)
         (setf tmp (nth i lst))
         (cond
           ((listp tmp)
            (print-list tmp))
           (t
            (write (nth i lst) :stream nil :escape nil)
            )
           ) ;; end cond
         (if (< i (1- len)) (write #\Space :stream nil :escape nil))
         ) ;; end dotimes
       (write #\) :stream nil :escape nil)
       ) ;; end (listp lst)
      ) ;; end cond
    (finish-output)
    (return-from print-list lst)
    ) ;; end let
  )

(defun adj-cell-addr (adj)
"隣接リスト内のセル[vertex]を[RxCy]形式の文字列に変換したリストを返す。
[adj-list]  ::=([node]...)
[node]      ::=([vertex] [weight] [inference type] [link type] [(label..)])"
  (cond
    ((null adj) nil)
    (t (append (list (cell-addr (first adj))) (rest adj)))))

(defun adj-list-cell-addr (adj-list)
  (let ((p nil))
    (dolist (adj adj-list)
      (push (adj-cell-addr adj) p))
    (return-from adj-list-cell-addr (reverse p))))

(defun nice-p-cell-addr (nice-path)
"nice-pが返すリスト中のセル・アドレスを[RxCy]形式の文字列に変換したリストを返す。"
  (cond
    ((null nice-path) nil)
    (t (list (cell-addr (nth 0 nice-path)) (nth 1 nice-path)
             (nth 2 nice-path) (cell-addr (nth 3 nice-path))))))

;;---------------------------------------------------------------------------
(defun debug-write-p (str &optional (echo nil))
"*debug-point*に[str]が登録されている場合のみ[t]を返す。
*debug-point*に["*"]が登録されている場合は常に[t]を返す。"
  (let (result)
    (setf result (debug-write-p-sub str))
    (when (and echo result)
      (format t "~a\:" str)
      (finish-output)
      )
    (return-from debug-write-p result)))

(defun debug-write-p-sub (str)
  (cond
    ((eq str t) t)
    ((and (stringp str) (member str *debug-point* :test #'string=)) t)
    ((and (stringp str) (member "*" *debug-point* :test #'string=)) t)
    (t nil)))

(defun debug-point (&optional (str t switch))
"debug-write用のタグとなる文字列を、対象リストをリセットしてから登録する。
引数がなければ現在登録されている文字列のリストを返す。
既存の対象リストに追加したい場合は add-debug-point を使う。"
  (cond
    ((null switch)
     *debug-point*)
    ((null str) ;; 明示的に nil が指定された
     (reset-debug-point))
    (t
     (reset-debug-point)
     (add-debug-point str))))

;;; debug-write用のタグとなる文字列を追加する。
;;; 既に登録済みの文字列は重複して登録しない。
(defun add-debug-point (str)
  (cond
    ((and (stringp str) (not (member str *debug-point* :test #'string=)))
     (push str *debug-point*))
    (t nil))
  (return-from add-debug-point *debug-point*))

;;; debug-write用のタグとなる文字列を登録済みの文字列リストから削除する。
(defun del-debug-point (str)
  (when (and (stringp str) (member str *debug-point* :test #'string=))
    (setf *debug-point* (remove str *debug-point* :test #'string=)))
  (return-from del-debug-point *debug-point*))

;;; debug-write用の文字列リストをリセットする。
(defun reset-debug-point ()
  (setf *debug-point* nil))
;;---------------------------------------------------------------------------

(defun debug-level (&optional (level nil))
"デバッグ・レベルを設定する。"
  (cond
    ((null level) *debug-level*)
    ((integerp level) (setf *debug-level* level))
    (t nil)))

(defun check-backtrack-point (&optional (val nil switch))
"試行錯誤関数がバックトラックする際に情報を出力するかどうかを設定する。"
  (cond
    ((null switch) *check-backtrack-point*)
    (t (setf *check-backtrack-point* val))))

(defun print-check (&optional (val nil switch))
"手筋を解説するボードを出力するかどうかを設定する。"
  (cond
    ((null switch) *print-check*)
    (t (setf *print-check* val))))

(defun need-multiple-answer (&optional (val nil switch))
"複数解を探索するかどうかを設定する。"
  (cond
    ((null switch) *need-multiple-answer*)
    (t (setf *need-multiple-answer* val))))

(defun chain-trim (&optional (val nil switch))
"刈り込み中に確定値が発生した際に再帰的(連鎖的)な刈り込みを行うかどうかを設定する。
知見を得るために実験的に刈り込み不十分な場合の動作観察のために設けた機能。
再帰的に完全な刈り込みを行わないと、後続の動作で不具合が発生するので、常にオンにすること。"
  (cond
    ((null switch) *chain-trim*)
    (t (setf *chain-trim* val))))

(defun auto-trim-level (&optional (val nil switch))
"simple-numberplaceの途中で刈り込みを行うかどうかを判断する未確定セル数の既定比率を設定する。
関数[chain-trim]のdescribe情報を参照。常に100%に設定すること。"
  (cond
    ((null switch) *auto-trim-level*)
    ((<= 0 val 100) (setf *auto-trim-level* val))))

(defun trim-every-time (&optional (val nil switch))
"候補が確定する都度その場で刈り込みを行うかどうかを設定する。
関数[chain-trim]のdescribe情報を参照。常に[t]に設定する。"
  (cond
    ((null switch) *trim-every-time*)
    (t (setf *trim-every-time* val))))

(defun n-grid-limit (&optional (val nil switch))
"グリッド解析の上限を設定する。[nil]は制限なし。[0]はグリッド解析不使用。"
  (cond
    ((null switch) *n-grid-limit*)
    ((null val) (setf *n-grid-limit* nil))
    ((and (integerp val) (<= 0 val *board-size*)) (setf *n-grid-limit* val))))

(defun tuples-limit (&optional (val nil switch))
"n国同盟探索の上限を設定する。[nil]は制限なし。[0]はn-tuples使用せず。"
  (cond
    ((null switch) *tuples-limit*)
    ((null val) (setf *tuples-limit* nil))
    ((and (integerp val) (<= 0 val *board-size*)) (setf *tuples-limit* val))))

(defun min-nice-length (&optional (len 3 switch))
"Nice Loopとして許可する連鎖の最短長さを設定する([3]以上)。"
  (cond
    ((null switch)
     *min-nice-length*)
    ((and (integerp len) (< len 3))
     (setf *min-nice-length* 3))
    ((integerp len)
     (setf *min-nice-length* len))))

(defun max-nice-length (&optional (len nil switch))
"Nice Loopとして許可する連鎖の最大長を設定する([3]以上)。
関数[min-nice-length]も参照。"
  (cond
    ((null switch)
     *max-nice-length*)
    ((null len)
     (setf *max-nice-length* nil))
    ((and (integerp len) (>= len 3))
     (setf *max-nice-length* len))
    (t *max-nice-length*)))

(defun max-nice-loops (&optional (len nil switch))
"ひとつの盤面に対して採用するNice Loopの最大経路数。[nil]は無制限。"
  (cond
    ((null switch)
     *max-nice-loops*)
    ((null len)
     (setf *max-nice-loops* nil))
    ((and (integerp len) (>= len 1))
     (setf *max-nice-loops* len))
    (t *max-nice-loops*)))

(defun output-nice-graph (&optional (val nil switch))
"GraphViz用のデータ・ファイルを出力するかどうかを設定する。
引数がなければ現在の設定を返す。"
  (cond
    ((null switch)
     *output-nice-graph*)
    (t (setf *output-nice-graph* val))))

(defun permitted-methods (&optional (val nil switch))
"許可する手筋に対応する関数名のリストを設定する。
引数がなければ現在の設定内容を返す。"
  (cond
    ((null switch) *permitted-methods*)
    ((null val) (setf *permitted-methods* nil))
    ((listp val) (setf *permitted-methods* val))
    (t (setf *permitted-methods* (list val)))))

(defun think-depth (&optional (val nil switch))
"手筋の「先読み」を許可するかどうかを設定する。"
  (cond
    ((null switch)
     *think-depth*)
    ((null val)
     (setf *think-depth* nil))
    ((and (integerp val) (zerop val))
     (setf *think-depth* nil))
    ((integerp val)
     (setf *think-depth* val))
    (t (error "think-depth:nilか数値を与えて下さい。~%"))))

(defun find-logical-path (board)
"理詰めだけで解に到達できる手筋のリストを返す。
用意されているどの手筋でも手を進められない盤面を発見したときは事後に
[(evil-boards)]で呼び出せる。手筋適用回数は[(applied-logics)]で呼び出せる。"
  (let (brd-1 brd-2 methods method env top result deep-count once-flag)
  ;;(let (brd-1 brd-2 applied methods method env top result deep-count once-flag)

    ;; 統計情報等採取用変数の初期設定。
    (applied-logics 0)  ; 手筋適用回数
    (evil-boards nil)   ; 悪魔の盤面。指定された手筋の組み合わせでは解けない盤面
    (setf deep-count 0) ; デバッグ情報表示で使うのみ
    (setf once-flag t)  ; デバッグ情報表示で使うのみ

    ;; 盤面等の初期設定。
    (setf result nil)
    (setf env nil)
    (setf brd-1 (clean-up-board (pm board)))    ; 盤面を刈り込んでペンシルマーク形式にする
    (setf brd-2 (new-board brd-1))              ; データの複製を作っておく

    ;; スタックの初期設定。[保存環境] ::= ( ([既適用手筋] [未適用手筋] [盤面] ) ... )
    (push (list nil (permitted-methods) brd-1) env)

    (loop
       (if (null env) (return-from find-logical-path (values (reverse result) (applied-logics))))
       (setf top (pop env))
       ;; [methods] ::= [未適用手筋] 
       (setf methods (second top))
       (setf brd-1 (third top))

      ;; デバッグ情報の表示
       (when (debug-write-p "find-logical-path")
         (incf deep-count)
         (when (> deep-count 10)
           (when once-flag
             (format t "deep thinking")
             (setf once-flag nil)
             )
           (princ *period-mark*)
           (force-output)
           (setf deep-count 0) ) )

       ;; 適用可能な手筋を探す。もしあれば適用した手筋と適用後のボードを、
       ;; それぞれのスタックに記録する。back-trackしてきた場合に備えて適用
       ;; 可能手筋(=[適用可能手筋]-[適用手筋])もスタックに記録。
       (loop
          (when (null methods)
            ;; 使用可能な手筋が尽きた。一段階前に戻る。
            ;; 一段階前の使用可能手筋は前回使用した手筋を除いたものに設定済み。
            (evil-boards (new-board brd-1))
            (return))
          (setf method (first methods))
          (setf brd-1 (funcall method brd-1))
          (applied-logics (1+ (applied-logics)))
          (cond
            ((finished-p brd-1) ;; 解に到達。
             (setf result (mapcar #'first env))
             (push method result)
             (return-from find-logical-path (values (reverse result) (applied-logics))))
            ((not (equal-board-p brd-1 brd-2)) ;; 手を進めることが出来た。
             ;; 使用した手筋を使用可能手筋から除外し、適用後の盤面と共にスタックに記録。
             (setf methods (set-difference methods (list method) :test #'equal))
             (setf brd-2 (new-board brd-1))
             (push (list method methods brd-2) env)
             ;; 次段階の用意。
             (push (list nil (permitted-methods) brd-2) env)
             (return) )
            (t (pop methods))) ;; 手を進めることが出来なかった。次の手筋へ。
          )
       )
    (return-from find-logical-path (values (reverse result) (applied-logics))) ) )

(defun do-logical-path (board logical-path)
"指定された手筋のリストに従って処理を行う。
[logical-path]には[find-logical-path]が返す手筋のリストを与えることを想定している。"
  (let (brd)
    (setf brd (pm (new-board board)))
    (dolist (i logical-path)
      (setf brd (funcall i brd)))
    (return-from do-logical-path (clean-up-board brd))))

(defun space-char-is (&optional (ch nil switch))
"盤面に表示する「空白文字」を設定する。"
  (cond
    ((null switch)
     (identity *spc*))
    ((null ch)
     (setf *spc* " "))
    ((characterp ch)
     (setf *spc* ch))
    ((and
      (stringp ch)
      (= (length ch) 1))
     (setf *spc* ch))
    (t (do-nothing))))

(defun print-chunk (&optional (val nil switch))
"解を数字列形式でも出力するかどうかを設定する。
引数なしの場合は現在の設定値を返す。
引数が確定値と未確定値のみからなるboard型データであればボードを表す数字列を出力する。"
  (cond
    ((null switch) *print-chunk*)
    ((no-candidate-p val)
     (princ (board2chunk val)))
    (t (setf *print-chunk* val))))

(defun easy-method-first (&optional (val nil switch))
"常に易しい手筋を優先して適用するかどうかを設定する。
手筋の「易しさ」は[(permitted-methods '(m-1 m-2 ...))]で登録するリストの順序。"
  (cond
    ((null switch) *easy-method-first*)
    (t (setf *easy-method-first* val))))
  
(defun tabs (n)
  (dotimes (i n) (format t "~T")))

(defun new-page (&optional (s nil sw))
"大きなサイズの盤面表示毎に改ページを出力する。
  (new-page t)   とすると以後 (new-page) を実行すると改ページを出力する。
  (new-page nil) とすると以後 (new-page) を実行しても改ページを出力しない。"
  (cond
    ((and (null sw) (identity *output-new-page*))
     (format t "~|")
     (force-output))
    ((identity s)
     (setf *output-new-page* t))
    ((null s)
     (setf *output-new-page* nil))))

(defun print-depth ()
  (when (>= (depth) 0)
    (tabs (depth))
    (format t "~d:~d> " (exec-count) (depth))))

(defun pure-listp (obj)
"引数が[nil]でないリストなら[t]を返す。"
  (return-from pure-listp (and obj (listp obj))))

(defun zero-or-positive-integerp (n)
"与えられた引数が0(ゼロ)以上の整数なら[t]を返し、そうでないなら[nil]を返す。"
  (return-from zero-or-positive-integerp (and (integerp n) (>= n 0)))
  )

(defun cell-addr (cell)
"セル・アドレスを \"rxcy\" 形式の文字列として返す。左上は \"r1c1\"。
関数[capital-address]も参照。"
  (cond
    ((null cell) nil)
    ((or (null (first cell)) (null (second cell))) nil)
    ((null (capital-address))
     (format nil "r~dc~d" (1+ (first cell)) (1+ (second cell))))
    ((capital-address)
     (format nil "R~dC~d" (1+ (first cell)) (1+ (second cell))))
    (t nil)))

(defun cell-list-addr (cell-list)
"セル・アドレスのリストを与えると[cell-address]形式アドレスのリストを返す。"
  (return-from cell-list-addr (mapcar #'cell-addr cell-list)))

(defun inf-type-str (inf-type-list)
"inference typeとラベルのリストを Nice loop記法の文字列に変換して返す。"
  (cond
    ((equal (first inf-type-list) 'strong)
     (format nil "=~s=" (first (second inf-type-list))))
    ((equal (first inf-type-list) 'weak)
     (format nil "-~s-" (first (second inf-type-list))))))

(defun dist (cell-1 cell-2)
"[cell-1]と[cell-2]の距離を返す。"
  (let (result)
    (setf result
          (+ (abs (- (first cell-1) (first cell-2))) ;距離を「重み」と定義する。
             (abs (- (second cell-1) (second cell-2)))))
    (return-from dist result)))

(defun set-equal (p q)
"ふたつの引数が集合として等しいかどうかを返す。"
  (let (result)
    (setf result nil)
    (when (and (listp p) (listp q))
      (if (< (length p) (length q)) (rotatef p q))
      (setf result (not (set-difference p q :test #'equal))))
    (return-from set-equal result)))

(defun do-nothing ()
"何もしない関数。"
  nil)

(defun plot-difficulty (method point p-width mark)
"各段階での解法の難易度をプロットする。

CLISPは書式指示子「~mincolA」では「半角文字」を1カラム幅、「全角文字」を2カラム幅とカウントする。
SBCLは「全角文字」も「半角文字」も1カラム幅とカウントする。このため書式指示子で最小出力幅を指
定するとSBCLでは見た目の書式が崩れる。unicodeでの文字幅は
     http://www.unicode.org/Public/UNIDATA/EastAsianWidth.txt
によって決定すべきだが「重い」ので、プログラマが指定することとした。[p-width]にメッセージを
出力する「幅」を与える。"
  (cond
    ((null (plot-level)) nil)
    ((zerop (plot-level))
     (format t "~d~%" point))
    ((= (plot-level) 1)
     (format t "~5,'0d(~2,'0d):" (method-count) point)
     (dotimes (i (floor point *scale*)) (princ " "))
     (princ mark)
     (terpri)
     (force-output))
    ((= (plot-level) 2)
     (dotimes (i (- *method-print-width* p-width)) (princ " "))
     (format t "~a:~5,'0d(~2,'0d):" method (method-count) point)
     (dotimes (i (floor point *scale*)) (princ " "))
     (princ mark)
     (terpri)
     (force-output))
    (t
     (plot-level 2)
     (plot-difficulty method point p-width mark)))
  (return-from plot-difficulty t))

(defun plot-level (&optional (val nil switch))
"難易度をプロットする場合のレベルを設定する。
引数なしなら現在の設定値を返す。"
  (cond
    ((null switch) *plot-level*)
    (t (setf *plot-level* val))))

(defun plot-info (name score &optional (wd nil) (mark "*"))
  (method-count (1+ (method-count)))
  (total-score (+ (total-score) score))
  (if (> score (max-score)) (max-score score))
  (if (null wd) (setf wd (length name)))
  (plot-difficulty name score wd mark)
  (return-from plot-info t))

(defun save-env ()
"現在の各種環境をスタックに保存する。"
  (push (debug-point) *np-environment*)
  (push (need-multiple-answer) *np-environment*)
  (push (check-backtrack-point) *np-environment*)
  (push (explanation-level) *np-environment*)
  (push (debug-level) *np-environment*)
  (push (print-mini) *np-environment*)
  (push (print-check) *np-environment*)
  (push (pencil-mark) *np-environment*)
  (push (auto-trim-level) *np-environment*)
  (push (chain-trim) *np-environment*)
  (push (max-nice-length) *np-environment*)
  (push (tuples-limit) *np-environment*)
  (push (n-grid-limit) *np-environment*)
  (push (plot-level) *np-environment*)
  (push (think-depth) *np-environment*)
  (push (permitted-methods) *np-environment*)
  (push (print-chunk) *np-environment*)
  (push (permit-cheat) *np-environment*)
  (push (als-show-all) *np-environment*)
  (push (als-show-stat) *np-environment*)
  (push (gb-als-show-all) *np-environment*)
  (return-from save-env *np-environment*))

(defun restore-env ()
"スタックに保存されている各種環境を1段階分復元する。"
  (gb-als-show-all (pop *np-environment*))
  (als-show-stat (pop *np-environment*))
  (als-show-all (pop *np-environment*))
  (permit-cheat (pop *np-environment*))
  (print-chunk (pop *np-environment*))
  (permitted-methods (pop *np-environment*))
  (think-depth (pop *np-environment*))
  (plot-level (pop *np-environment*))
  (n-grid-limit (pop *np-environment*))
  (tuples-limit (pop *np-environment*))
  (max-nice-length (pop *np-environment*))
  (chain-trim (pop *np-environment*))
  (auto-trim-level (pop *np-environment*))
  (pencil-mark (pop *np-environment*))
  (print-check (pop *np-environment*))
  (print-mini (pop *np-environment*))
  (debug-level (pop *np-environment*))
  (explanation-level (pop *np-environment*))
  (check-backtrack-point (pop *np-environment*))
  (need-multiple-answer (pop *np-environment*))
  (let (lst)
    (reset-debug-point)
    (setf lst (pop *np-environment*))
    (dolist (i lst) (add-debug-point i))) ;; 2023-12-06
  (return-from restore-env *np-environment*))

(defun reset-env ()
"各種環境を初期化する。novice-level, middle-level, senior-level, advanced-level
machine-levelが設定する環境は変化させない。"
  (reset-counter)
  (permit-cheat t)
  (reset-debug-point)
  (plot-level nil)
  (debug-level 0)
  (pause nil)
  (print-mini t)
  (print-check nil)
  (explanation-level 0)
  (board-print-counter 0)
  (check-backtrack-point nil)
  (need-multiple-answer t)
  (setf *np-environment* nil))

(defun reset-counter ()
  (answer nil)
  (depth nil) ;; reset *depth* and *max-depth* to zero.
  (exec-count 0)
  (nice-depth nil)
  (nice-count 0)
  (method-count 0)
  (total-score 0)
  (max-score 0)
  (linkmap-counter 0)
  )

(defun print-env ()
"現在の各種環境を表示する。"
  (mapcar #'(lambda (x) (format t "~s~%" x)) (current-env))
  (print-preset-level)
  (return-from print-env t))

(defun print-preset-level ()
  (let (len)
    (mapcar #'(lambda (x) (format t "~s~%" x)) (current-preset-level))
    (format t "(permitted-methods '(")
    (setf len (length (permitted-methods)))
    (dotimes (i len)
      (princ (nth i (permitted-methods)))
      (if (< i (1- len)) (princ " ")))
    (princ "))")
    (terpri)
    (return-from print-preset-level t)))

(defun current-env ()
"現在の設定環境を返す。"
  (list
   (list 'print-mini (print-mini))
   (list 'print-normal (print-normal))
   (list 'print-check (print-check))
   (list 'pencil-mark (pencil-mark))
   (list 'check-backtrack-point (check-backtrack-point))
   (list 'need-multiple-answer (need-multiple-answer))
   (list 'explanation-level (explanation-level))
   (list 'permit-cheat (permit-cheat))
   (list 'als-show-all (als-show-all))
   (list 'als-show-stat (als-show-stat))
   ;;(list 'debug-level (debug-level))
   ;;(list 'debug-point (debug-point))
   (list 'pause (pause))
   (list 'space-char-is (space-char-is))
   (list 'plot-level (plot-level))))

(defun current-preset-level ()
"現在のプリセットレベルを返す。"
  (list (list 'n-grid-limit (n-grid-limit))
        (list 'tuples-limit (tuples-limit))
        (list 'max-nice-length (max-nice-length))
        (list 'max-nice-loops (max-nice-loops))
        (list 'easy-method-first (easy-method-first))
        (list 'think-depth (think-depth))
        (list 'permit-cheat (permit-cheat))
        (list 'als-show-all (als-show-all))
        (list 'als-show-stat (als-show-stat))
        ;;(list 'auto-trim-level (auto-trim-level))
        ;;(list 'chain-trim (chain-trim))
        ;;(list 'trim-every-time (trim-every-time))
        )
  )

(defun block-size (&optional (val nil sw))
"引数で指定された値を既定のブロックサイズに設定し、それに合わせて*np-digit*を設定する。
引数がなければ現在の既定値を返す。"
  (let (tmp)
    (setf tmp nil)
    (cond
      ((null sw) *block-size*)
      ((<= val 1) (error "ブロック・サイズは2x2以上でないと無意味です。"))
      (t (setf *block-size* val)
         (setf *board-size* (* *block-size* *block-size*))
         (setf *np-digit* (dotimes (i *board-size* (reverse tmp)) (push (1+ i) tmp)))))
    (return-from block-size *block-size*)))

(defun board-size (&optional (board nil))
"引数で指定されたボードのボード・サイズを返す。
引数がなければ現在の既定ボード・サイズを返す。"
  (cond
    ((null board) *board-size*)
    ((board-p board) (first (array-dimensions board)))
    (t nil)))

(defun set-board-size (board)
"ボード・サイズを設定する。"
  (cond
    ((integerp board) (block-size (isqrt board)))
    ((board-p board) (set-board-size (first (array-dimensions board))))
    (t (error "引数にはボードのサイズかボードを表す配列を与えて下さい")))
  (return-from set-board-size *board-size*))

(defun snap-shot (&optional (p nil sw1) (q nil sw2) (r t))
"スナップ・ショットの作成／設定／表示を行う。デバッグ用。関数[set-snap-shot]を参照。
・引数がなければスナップ・ショットの現在の設定を表示する。
・第1引数に nil が明示的に指定されていればスナップ・ショット設定用領域を廃棄する。
・第1引数がボード型変数なら同じサイズのスナップ・ショット設定用領域を用意する。
・数値ひとつ(p)だけが引数なら、その引数に対応するサイズ(p^2)の設定用領域を用意する。
・第1引数(p)と第2引数(q)が数値ならp行q列に値(r)を設定する。
・上記以外なら何もせずにnilを返す。"
  (cond
    ((null sw1) (view-snap))
    ((null p) (setf *snap-shot* nil))
    ((board-p p) (new-snap-shot p))
    ((and (integerp p) (null sw2)) (new-snap-shot p))
    ((and (integerp p) (integerp q)) (set-snap-shot p q r))))

(defun new-snap-shot (brd)
"新規にスナップ・ショット用の登録領域を作成する。"
  (let ((size nil))
    (cond
      ((null brd) nil)
      ((integerp brd) (setf size brd))
      ((arrayp brd) (setf size (board-size brd))))
    (when (integerp size)
      (setf *snap-shot* (make-array (list size size) :initial-element nil))
      (return-from new-snap-shot t))))

(defun set-snap-shot (i j &optional (val t))
"ボードのi行j列の候補が1つになったら、そのときのボードを出力するように設定する。
オプショナル引数に数値が指定されていたときは、その数値が唯一の候補となったとき
に、その状態のボードを出力する。ボードの左上を1行1列とする。"
  (cond
    ((null *snap-shot*) nil)
    ((and (integerp val) (>= (board-size) val 1)) (setf (aref *snap-shot* (1- i) (1- j)) val))
    ((integerp val) (format t "その数字はあり得ません。"))
    ((arrayp *snap-shot*) (setf (aref *snap-shot* (1- i) (1- j)) val)))
  (return-from set-snap-shot (view-snap)))

(defun view-snap ()
"現在のスナップ・ショットを表示する。"
  (print-mini *snap-shot*))

(defun snap-shot-p (i j &optional (val t))
"内部表現のi行j列にスナップ・ショットが登録されているかどうかを返す。
オプショナル引数に数値が指定されていた場合は、その数値の場合にtを返す。"
  (cond
    ((null *snap-shot*) nil)
    ((not (arrayp *snap-shot*)) nil)
    ((integerp (aref *snap-shot* i j)) (= (aref *snap-shot* i j) val))
    (t (aref *snap-shot* i j))))

(defun print-snap-shot (board i j)
"スナップ・ショットに関する情報を出力する。"
  (print-depth)
  (format t "@ ~d回目の試行錯誤中に" (exec-count))
  (cond
    ((integerp (aref *snap-shot* i j))
     (format t "~d行~d列の候補が指定の値(~d)になりました。~%" (1+ i) (1+ j) (aref board i j)))
    ((eq (aref *snap-shot* i j) t)
     (format t "~d行~d列の候補が唯一の値(~d)になりました。~%" (1+ i) (1+ j) (aref board i j))))
  (print-board board))

(defun print-blank-board (&optional (p t switch))
"要素がすべて[0]の既定サイズのボードを返す。人間のナンプレ用メモとして便利。
既定サイズを変更するには (set-board-size \"board-size\") を実行する。
・引数がなければ2次元配列として返す。
・引数が[nil]ならprint-miniによって出力する。
・引数が[nil]以外ならprint-normalによって出力する。"
  (let (blank)
    (setf blank (make-array (list *board-size* *board-size*) :initial-element 0))
    (cond
      ((null switch) blank)
      ((null p) (print-mini blank))
      (t (print-normal blank)))))

(defun output-graphviz-data (graph &optional (fname "LinkMap-"))
"GraphViz(http://www.graphviz.org/)用のデータ・ファイルとしてセル間のリンク関係を出力する。
GraphVizのコマンド

    > dot -Tpng LinkMap-xxx.gv -o LinkMap-xxx.png

によって画像ファイルが得られる。[png]部分は[gif]なども可。詳しくはGraphVizのマニュアル参照。
[xxx]は3桁の数字で出力ごとに[1]増える。[numberplace]関数実行毎に[001]に戻る。"
  (let (adj inf-type fmt color-info-list colors tmp (used nil) (link-pair nil))
    (setf fmt (format nil "~a~3,'0d.gv" fname (linkmap-counter)))
    (with-open-file (s fmt :direction :output :if-exists :overwrite :if-does-not-exist :create)
      (format s "graph LinkMap {~%")
      (format s "graph [rankdir = LR, ")
      (format s "fontname = \"arial\", fontsize = 10];") ;
      (format s "node [shape=ellipse];~%")
      (dotimes (i *board-size*)
        (dotimes (j *board-size*)
          (when (typep (aref graph i j) 'vertex)
            (push (list i j) used)
            ;;[adj] ::=( ([vertex] [weight] [inference type] [link type] [(label..)])... ) ;
            (setf adj (vertex-adj-list (aref graph i j)))
            (dolist (node adj)
              (when (not (member (list (first node) (list i j)) link-pair :test #'equal))
                (push (get-vertex node) used)
                (push (list (list i j) (get-vertex node)) link-pair)
                (format s "~a --" (cell-addr (list i j)))
                (format s " ~a " (cell-addr (get-vertex node)))
                (setf inf-type (get-inf node))
                (cond
                  ((equal inf-type 'strong)
                   (format s "[label=\"+~s\", dir=both" (get-labels node)))
                  ((equal inf-type 'weak)
                   (format s "[label=\"-~s\", dir=both" (abs-label (get-labels node)))))
                ;; [color-info-list] ::= ( [color-info]... ) ;
                ;; [color-info] ::= ([cell] ( [color] [style] )) ;
                (setf color-info-list (vertex-edge-color (aref graph i j)))
                (when (identity color-info-list)
                  (setf colors nil)
                  (dolist (color-info color-info-list)
                    (if (equal (first color-info) (first node))
                        (push (second color-info) colors)))
                  ;; [colors] ::= ( [color] [style] )... ;
                  (cond
                    ((null colors) nil)
                    ((= (length colors) 1)
                     (cond
                       ((equal (second (first colors)) 'continuous)
                        (format s ", penwidth=5, style=solid, color=\"~s\"" (caar colors)))
                       ((equal (second (first colors)) 'discontinuous)
                        (format s ", penwidth=5, style=dashed, color=\"~s\"" (caar colors)))))
                    ((> (length colors) 1)
                     (setf tmp nil)
                     (cond
                       ((equal (cadar colors) 'continuous)
                        (format s ", penwidth=5, style=solid, color=\""))
                       ((equal (cadar colors) 'discontinuous)
                        (format s ", penwidth=5, style=dashed, color=\"")))
                     (dolist (k (butlast colors))
                       (if (not (member k tmp :test #'equal)) (format s "~s:" (first k)))
                       (push k tmp) )
                     (if (not (member (first (last colors)) tmp :test #'equal))
                         (format s "~s" (first (first (last colors)))))
                     (format s "\"") )))
                (format s "];~%"))))))
      (format s "overlap=false~%}~%"))
    (return-from output-graphviz-data t)))

(defun output-nice-colors (graph nice-path-list colors)
"Nice Loopのリンク図[nice-path-list]を[colors]で指定される色ごとに彩色して出力する。
 ・[colors]が数値ならnice loopを先頭から[colors]個ごとに彩色したグラフ・データを出力する。
 ・[colors]がリストなら[colors]の要素で指定される色ごとに彩色したグラフ・データを出力する。
[nice-path]::= ({continuous|discontinuous} ([cell-0] [inf-type] [label] [cell-1])...) ;"
  (let (nice-loops nice-print len num q r)
    (setf nice-loops nice-path-list)
    (setf len (length nice-path-list))

    (cond
      ((null colors)
       (setf num (length *edge-colors*)))
      ((and (integerp colors) (> colors 0))
       (setf num colors))
      ((listp colors)
       (setf num (length colors)))
      (t (error "can't happen at output-nice-colors.")))

    (setf q (floor len num) r (mod len num))

    (when (debug-write-p "output-nice-colors")
      (format t "colors=~s~%" colors)
      (format t "len=~d~%" len)
      (format t "num=~d~%" num)
      (format t "q=~d, r=~d~%" q r))

    (dotimes (i q)
      (setf nice-print nil)
      (dotimes (j num)
        (push (pop nice-loops) nice-print))
      (setf nice-print (reverse nice-print))
      (graphviz-edge-color graph nice-print num colors)
      (output-graphviz-data graph "LinkMap-")
      (clear-graphviz-edge-color graph nice-print))

    (graphviz-edge-color graph nice-loops r colors)
    (output-graphviz-data graph "LinkMap-")

    (return-from output-nice-colors t)))

(defun graphviz-edge-color (graph nice-path-list target &optional (colors *edge-colors*))
"GraphViz用にエッジの色を指定する。
[nice-path-list]で指定されるNice Loopのエッジを彩色する。
彩色するNice Loopは[target]で指定する。
    ・[target]が[nil]ならすべてを彩色する。
    ・[target]が数値[n]なら[nice-path-list]の先頭から[n]個を彩色する。
      [nice-path-list]の要素数が[n]に満たないときはすべてを彩色する。
    ・[target]がリストなら,リスト内の数値で指定されるNice Loopのエッジのみを彩色する。
      [nice-path-list]に登録されている最初のNice Loopの位置を[0]番目とする。"
  (let (ncolor n num edge-type imp-info-list top-cell last-cell)
    ;;[nice-path]::= ({continuous|discontinuous} ([cell-0] [inf-type] [label] [cell-1])...) ;
    (setf ncolor (length colors) n 0)
    (cond
      ((null target)
       (dolist (nice-path nice-path-list)
         (setf edge-type (first nice-path))
         (setf imp-info-list (rest nice-path))
         (setf top-cell (nth 0 (nth 0 imp-info-list)))
         (setf last-cell (nth 0 (first (last imp-info-list))))
         (dolist (imp-info imp-info-list)
           ;; [edge-color] ::= ( [color] [style] ) ;
           (set-edge-color
            graph (list (nth n colors) edge-type) (nth 0 imp-info) (nth 3 imp-info)))
         (set-edge-color graph (list (nth n colors) edge-type) last-cell top-cell)
         (setf n (mod (incf n) ncolor)) ))
      ((listp target)
       (dolist (p target)
         (when (and (integerp p) (<= 0 p (length nice-path-list)))
           (setf edge-type (first (nth p nice-path-list)))
           (setf imp-info-list (rest (nth p nice-path-list)))
           (setf top-cell (nth 0 (nth 0 imp-info-list)))
           (setf last-cell (nth 0 (first (last imp-info-list))))
           (dolist (imp-info imp-info-list)
             (set-edge-color
              graph (list (nth n colors) edge-type) (nth 0 imp-info) (nth 3 imp-info)))
           (set-edge-color graph (list (nth n colors) edge-type) last-cell top-cell)
           (setf n (mod (incf n) ncolor)) )))
      ((and (integerp target) (>= target 0))
       (setf num (min (length nice-path-list) target))
       (dotimes (i num)
         (setf edge-type (first (nth i nice-path-list)))
         (setf imp-info-list (rest (nth i nice-path-list)))
         (setf top-cell (nth 0 (nth 0 imp-info-list)))
         (setf last-cell (nth 0 (first (last imp-info-list))))
         (dolist (imp-info imp-info-list)
           (set-edge-color
            graph (list (nth n colors) edge-type) (nth 0 imp-info) (nth 3 imp-info)))
         (set-edge-color graph (list (nth n colors) edge-type) last-cell top-cell)
         (setf n (mod (incf n) ncolor)) ))
      (t nil))))

(defun clear-graphviz-edge-color (graph nice-path-list)
"GraphViz用のエッジを彩色する色指定をクリアする。"
  (let (imp-info-list top-cell last-cell) ;[imp] is abbreviation for [implication].
    ;;[nice-path]::= ({continuous|discontinuous} ([cell-0] [inf-type] [label] [cell-1])...) ;
    (dolist (nice-path nice-path-list)
      (setf imp-info-list (rest nice-path))
      (setf top-cell (nth 0 (nth 0 imp-info-list)))
      (setf last-cell (nth 0 (first (last imp-info-list))))
      (dolist (imp-info imp-info-list)
        (clear-edge-color graph (nth 0 imp-info) (nth 3 imp-info)))
      (clear-edge-color graph last-cell top-cell))
    (return-from clear-graphviz-edge-color t)))

(defun set-edge-color (graph color cell-0 cell-1)
"グラフ[graph]のセル[cell-0]とセル[cell-1]の間のエッジ(辺)の色を[color]と指定する。"
  (set-edge-color-one-way graph color cell-0 cell-1)
  (set-edge-color-one-way graph color cell-1 cell-0))

(defun set-edge-color-one-way (graph color cell-0 cell-1)
"グラフ[graph]のセル[cell-0]からセル[cell-1]へのエッジ(辺)の色を[color]と指定する。
[cell-0]のスロット[edge-color]に[cell-1]と[color]を組にしたリストが追加される。
操作に成功すれば ([color] [cell-0] [cell-1]) を返す。そうでなければ[nil]を返す。"
  (let (ok row-0 col-0 row-1 col-1)
    (setf row-0 (first cell-0) col-0 (second cell-0))
    (setf row-1 (first cell-1) col-1 (second cell-1))
    (setf ok (and (typep (aref graph row-0 col-0) 'vertex)
                  (typep (aref graph row-1 col-1) 'vertex)))
    (if (not ok) (return-from set-edge-color-one-way nil))
    (push (list cell-1 color) (vertex-edge-color (aref graph row-0 col-0)))
    (return-from set-edge-color-one-way (list color cell-0 cell-1))))

(defun clear-edge-color (graph cell-0 cell-1)
"グラフ[graph]のセル[cell-0]とセル[cell-1]の間の辺に対するカラー指定を削除する。"
  (clear-edge-color-one-way graph cell-0 cell-1)
  (clear-edge-color-one-way graph cell-1 cell-0))

(defun clear-edge-color-one-way (graph cell-0 cell-1)
"グラフ[graph]のセル[cell-0]からセル[cell-1]への辺に対するカラー指定を削除する。
実際に削除できたのであれば[t],そうでなければ[nil]を返す。"
  (let (ok color-info (lst nil) (cell-exist nil))
    (setf ok (and (typep (aref graph (first cell-0) (second cell-0)) 'vertex)
                  (typep (aref graph (first cell-1) (second cell-1)) 'vertex)))
    (if (not ok) (return-from clear-edge-color-one-way nil))
    (setf color-info (vertex-edge-color (aref graph (first cell-0) (second cell-0))))
    (dolist (edge-color-spec color-info)
      (cond
        ((equal (first edge-color-spec) cell-1)
         (setf cell-exist t))
        (t (push edge-color-spec lst))))
    (when cell-exist
      (setf (vertex-edge-color (aref graph (first cell-0) (second cell-0))) (reverse lst)))
    (return-from clear-edge-color-one-way cell-exist)))

(defun help (&optional (item nil))
"主なヘルプを表示する。(help \`help)でヘルプ方法のヘルプを表示する。"
  (cond
    ((null item)
     (help-for-overview)
     )
    ((or
      (equal item '?)
      (equal item 'help))
     (append (help-list) (mapcar #'car (help-methods)))
     )
    (t (help-for item))))

(defun select-methods-help ()
"ヘルプ項目を番号付き一覧から選択して表示する。関数[examin]内で使用。"
  (let (num)
    (setf num 0)
    (fresh-line) ;; for sbcl. "~3d~8t~a~%" の ~8tの動作に不具合がある(タブによる空白が初回のみ足りない)。
    (dolist (help-item (help-methods))
      (format t "~3d~8t~a~%" num (cdr help-item))
      (incf num)
      ) ;; dolist
    (finish-output)
    (loop
      (block select-methods-help-loop
	(format t "説明を表示したい手筋を番号で選んで下さい(終了は\"quit\")。~%")
	(format t "Enter number : ")
	(finish-output)
	(setf num (read))
	(clear-input)
	(if (member num '(quit q exit)) (return-from select-methods-help t)) ;; 終了。
	(when (not (and (integerp num) (<= 0 num (1- (length (help-methods))))))
           (format t "0から~dまでの範囲の番号しか選択できません。~%" (1- (length (help-methods))))
	   (return-from select-methods-help-loop nil)
           )
	(print-repeated-char-string 62 #\-)
	(help-for (car (nth num (help-methods))))
	(finish-output)
	) ;; end block
      )              ;; end loop
    (return-from select-methods-help t)
    ) ;; end let
  )

(defun help-methods ()
"ヘルプ・メッセージ用手筋名と表示用手筋名のペアリストのリストを返す。

[3]> (help-methods)
((fundamental . \"基本手筋\") (localization . \"ローカライゼーション\") (n-tuples . \"n国同盟\")
 (n-grid . \"nグリッド\") (almost-locked-set . \"Almost Locked Set\")
 (grid-based-almost-locked-set . \"Grid Based Almost Locked Set\")
 (pattern-overlay-method . \"配置確定法\") (advanced-coloring . \"Advanced Coloring\")
 (nice-loop . \"Nice Loop\"))"
  (let (i result tmp name-list)
    (setf i 0)
    (setf result nil)
    ;; ヘルプメッセージ用の手筋名と説明用手筋名のペアリストのリスト。
    (setf name-list (help-name-to-function-name-list))
    ;; (symbol-plist '*help-methods*) ==> ( ([help項目名] [項目の説明]) ... )
    (dolist (lst (symbol-plist '*help-methods*))
      (when (evenp i)
        (setf tmp (cdr (first (member lst name-list :key #'car))))
        (push (cons lst tmp) result)
        )
      (incf i)
      ) ;; end dolist
    (setf result (sort-as (copy-seq result) (function-name-to-tesuji-name-list) #'string=))
    (return-from help-methods result)
    )
  )

(defun help-name-to-function-name-list ()
"ヘルプ用手筋名と現在の言語設定(japanese/english)での表示用手筋名のペアリストのリストを返す。

(function-name-to-tesuji-name-list 'japanese) を実行後であれば

[25]> (help-name-to-function-name-list)
((fundamental . \"基本手筋\") (localization . \"ローカライゼーション\")
(n-tuples . \"n国同盟\") (n-grid . \"nグリッド\") (almost-locked-set . \"Almost Locked Set\")
(grid-based-almost-locked-set . \"Grid Based Almost Locked Set\")
(pattern-overlay-method . \"配置確定法\") (advanced-coloring . \"Advanced Coloring\")
(nice-loop . \"Nice Loop\"))"
  (let (name-list result)
    (setf result nil)
    (setf name-list (function-name-to-tesuji-name-list)) ;; 現在の関数名と手筋名のペアリストのリスト。
    (dolist (p *tesuji-help-name-to-function-name*)
      (dolist (q name-list)
        (if (equal (cdr p) (car q)) (push (cons (car p) (cdr q)) result))
        ) ;; end dolist
      ) ;; end dolist
    (setf result (sort-as (copy-seq result) (function-name-to-tesuji-name-list) #'string=))
    (return-from help-name-to-function-name-list result)
    ) ;; end let
  )

(defun sort-as (lst teacher-list &optional (predicate #'equal))
"[teacher-list]のリスト順に[lst]を整列したリストを返す。
両方のリストは、それぞれペアリストで、ペアリストの2番めの要素が一致していることが必要。"
  (let (result)
    (setf result nil)
    (dolist (p teacher-list)
      (dolist (q lst)
	(if (funcall predicate (cdr q) (cdr p)) (push q result))
	) ;; end dolist
      )	  ;; end dolist
    (return-from sort-as (reverse result))
    ) ;; end let
  )

(defun sort-as-simple-list (lst teacher-list &optional (predicate #'equal))
"[teacher-list]のリスト順に[lst]を整列したリストを返す。
両方のリストは、それぞれ単純なリスト。"
  (let (result)
    (setq result nil)
    (dolist (p teacher-list)
      (dolist (q lst)
	(if (funcall predicate q p) (push q result))
	) ;; end dolisp
      ) ;; end dolist
    (return-from sort-as-simple-list (reverse result))
    ) ;; end let
  ) ;; end sort-as-simple-list

(defun help-list ()
"表示可能なHelp項目名のリストだけを返す。"
  (let (i result)
    (setf i 1 result nil)
    (dolist (lst (symbol-plist '*help-item*))
      (if (oddp i) (push lst result)) ;; ( ([help項目名] [項目の説明]) ... )
      (incf i)
      ) ;; end dolist
    (setf result (sort (copy-seq result) #'symbol-lessp))
    (return-from help-list result)
    )
  )

(defun symbol-lessp (sym-1 sym-2)
  (string< (symbol-name sym-1) (symbol-name sym-2))
  )

(defun add-help (item body)
"個別のヘルプ内容を登録する関数。"
  (setf (get '*help-item* item) body)
  )

(defun add-methods-help (item body)
"手筋のヘルプを登録する関数。"
  (setf (get '*help-methods* item) body)
  )

(defun help-for (item)
  (let (help-methods-msg fname dir)
    (cond
      ((get '*help-item* item)
       (format t "~a" (get '*help-item* item))
       )
      ((setf help-methods-msg (get '*help-methods* item))
       (cond
	 ((not *can-use-external-less*) ;; [external-less]が使えないならば[format]関数で出力する。
	  (format t "~a" help-methods-msg)
	  )
	 ((identity *can-use-external-less*) ;; [external-less]が使用可能なら外部コマンドの[less]で表示する。
	  (setf dir (make-pathname :directory (list :relative ".NumberPlace-help")))
	  (ensure-directories-exist dir)
	  (setf fname (format nil "./.NumberPlace-help/~a.help" (string-downcase (symbol-name item))))
	  ;; [:if-exists nil]でないのはヘルプ・メッセージがアップデートされていた場合にファイルも書き変えるため。
	  (with-open-file (s fname :direction :output :if-does-not-exist :create :if-exists :overwrite)
	    (format s "~a" help-methods-msg)
	    )
	  (external-less fname)
	  )
	 (t
	  (error "can't happen.")
	  )
	 ) ;; end cond
       )   ;; end (setf ...
      )	   ;; end cond
    (finish-output)
    (return-from help-for t)
    ) ;; end let
  )

(defun help-for-overview ()
  (let ((help-message
         '(("(help \'help)" "個別に解説可能な項目の一覧を表示する。")
           ("(help \'[item])" "個別に解説可能な項目\[item\]の説明を表示する。")
           ("(teach \[board\])" "解と解法過程を表示する。")
           ("(plot \[board\])" "解法過程の難易度をグラフ表示する。")
           ("(stat \[board\])" "解と試行錯誤回数等の情報だけを表示する。")
           ("(examin \[board\])" "各盤面ごとに適用可能な手筋を示して、ユーザが選択的に手を進める。")
           ("(examin \"fname\")" "ファイルに保存された盤面データを読み込む。")
           ("(examin)" "盤面データを入力してから適用可能な手筋での検討を行う。")
           ("(simple-answer \[board\])" "問題自身と手筋適用後の盤面＋解を表示する。")
           ("(numberplace \[board\])" "解のリストを返す。エンジン部分。")
           ("(pencil-mark \[board\])" "刈り込みだけを行って盤面を表示する。")
           ("(pm \[board\])" "(pencil-mark \[board\])と同じ。")
           ("(enter-board)" "候補数字の初期値を入力する。空マスには[0]を入力。")
           ("(edit-board \[board\])" "ボードの候補数字を編集する。")
           nil ;; nil means terpri.
           ("表示制御関連の関数：" "")
           ("(print-mini {t|nil})" "盤面をコンパクトなサイズで表示するか設定する。")
           ("(print-normal {t|nil})" "盤面を候補数字付きのサイズで表示するか設定する。")
           ("(pencil-mark {t|nil})" "盤面の候補数字を固定位置に表示するか設定する。")
           ("(color-mode {0|1|2})" "Advanced Coloringの盤面表示に使用するカラー表示レベル。")
           ("(als-show-stat {t|nil})" "Almost Locked Setに関する統計情報を表示するか設定する。")
           ("(set-parity color-1 color-2)" "Advanced Coloringの盤面表示で使用する色指定。")
           ("(pause {nil|1..n})" "盤面を指定した数出力するごとに一時停止する。[nil]は一時停止なし。")
           ;;("(new-page {t|nil})" "[t]を指定すると大盤面表示毎に改ページを出力する。[nil]でオフ。")
           ("(print-check {t|nil}" "手筋を解説する小さな盤面を随時表示する。")
           ("(check-backtrack-point {t|nil})" "仮置きの際の盤面を出力するかどうかを設定する。")
           ("(need-multiple-answer {t|nil})" "複数解を探索するかどうかを設定する。")
           ("(explanation-level {bn})" "解法過程の解説表示レベルを設定する。")
           ("" "10の位[b]が盤面表示レベル。1の位[n]が解説表示レベル。")
           ("" "それぞれ[0]が出力なし,[1]が標準,[2]が全項目出力。標準は[11]。")
           nil ;; nil means terpri.
           ("動作制御関連の関数：" "")
           ("(n-grid-limit {nil|0..n})" "n-gridの上限を設定する。[nil]は上限なし。")
           ("(tuples-limit {nil|0..n})" "n国同盟の上限を設定する。[nil]は上限なし。")
           ("(max-nice-length {nil|3..n})" "Nice Loopの連鎖セル数上限を設定する。[nil]は上限なし。")
           ("(max-nice-loops {nil|1..n})" "盤面ごとに採用するNice Loopの最大数。[nil]は上限なし。")
           ("(als-show-all {t|nil})" "ALSで効率的パターンのみを表示するかを設定する。")
           ("(gb-als-show-all {t|nil})" "GB-ALSで効率的パターンのみを表示するかを設定する。")
           ("(easy-method-first {t|nil})" "易しい手筋を最優先で適用する。")
           ("(think-depth {nil|1..n})" "[n]手先まで読んで最善の手筋を適用する。[nil]は先読みなし。")
           ("(find-logical-path board)" "すべての手筋の組み合わせを尽くして解に到達できる手筋を探す。")
           ("(evil-boards)" "find-logical-pathでも解けなかった盤面を呼び出す。")
           ("(print-env)" "現在の設定値を表示する。")
           nil ;; nil means terpri.
           ("動作制御関数のプリセット：" "")
           ("(novice-level)" "初心者向けの動作設定。使用する手筋を限定。")
           ("(middle-level)" "初級から中級者向けの設定。")
           ("(senior-level)" "中級から上級者向けの設定。")
           ("(advanced-level)" "上級者向けの設定。")
           ("(machine-level)" "超上級者向けの設定。")
           ("(speed-first)" "速度最優先の設定。途中経過表示も一切なし。") ))
        (min-left-wd 30) left-wd max-left-wd mid-space len)
    (setf max-left-wd min-left-wd)
    (dolist (i help-message)
      (setf len (length (eval (first i))))
      (if (> len max-left-wd) (setf max-left-wd len))
      )
    (incf max-left-wd 2) ;; add more 2 spaces.
    (format t "NumberPlace.lisp Version ~a~%~%" (numberplace-version))
    (dolist (msg help-message)
      (cond
        ((null msg)
         (terpri))
        ((and (pure-listp msg) (= (length msg) 2))
         (setf left-wd (length (first msg)))
         (setf mid-space (- max-left-wd left-wd))
         (format t "~a" (eval (first msg)))
         (dotimes (i mid-space) (princ *space*))
         (format t "~a~%" (eval (second msg))))
        (t (do-nothing))))
    )
  ) ;; end help-for-overview

(add-methods-help 'fundamental
"基本手筋(hidden singles)

各数字が存在する可能性のあるセルの位置を刈り込みによって調べ、それが
   ・行内で唯一なら確定値。
   ・列内で唯一なら確定値。
   ・ブロック内で唯一なら確定値。

 hidden singlesとも呼ばれる。

自明ながら、行・列・ブロックで残り一つ以外の候補が確定しているのであれば、最後の一つも確定する。

例えば次の盤面で、3行9列の候補数字[3]はブロック3では唯一の候補数字なので3行9列は[3]に確定。
同時に3行9列の候補数字[3]は3行目で唯一の候補数字なので、行に注目しても3行9列は[3]に確定。
更に、3行9列の[3]は9列目で唯一の候補数字なので、列に注目しても3行9列は[3]に確定。

その結果盤面中の[X]の位置から候補を削除できる。

*) このケースでは3行9列の[3]は3行9列が含まれるハウス内でも唯一の候補数字なのでハウスに対しても確定値。
   ただし、行、列、ブロックのいずれかで3行9列の[3]が唯一の候補数字であることを発見すればハウスに対するチェックは必要ない。
#=======================================================================#
# 1 2 . | 1 . . | 1 . . # . . . | . . . | . 2 . # . 2 . | . 2 . | . 2 . #
# 4 5 6 | 4 . 6 | 4 . 6 # . 7 . | . 3 . | 4 . 6 # . 5 6 | . . . | . . 6 #
# . . . | . . 9 | . . . # . . . | . . . | . . . # . . . | . 8 9 | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . 2 . # . . . | . . . | . 2 . #
# . 5 6 | . 3 . | . 7 . # . 8 . | . 5 . | . . 6 # . 1 . | . 4 . | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . . . # . 2 . | . . . | . X G #
# 4 5 6 | . 8 . | 4 . 6 # . 9 . | 4 5 . | . 1 . # . 5 6 | . 7 . | . . X #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . 2 . | . . . # . . . | . 2 3 | . . . #
# 4 . . | 4 . . | . 5 . # . 6 . | 4 . . | . 8 . # . 9 . | . . . | . 1 . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . 3 # . . . | . . . | . 2 . # . 2 . | . 2 3 | . . . #
# . 9 . | 4 . 6 | 4 . 6 # . 5 . | . 7 . | 4 . . # . . 6 | . . . | . 8 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . . 6 | . . 6 | . 2 . # . 1 . | . 9 . | . 3 . # . 4 . | . 5 . | . . 6 #
# 7 8 . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . 3 . | . 2 . | . 9 . # . 4 . | . 1 . | . 7 . # . 8 . | . 6 . | . 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# 4 . . | . 5 . | . 8 . # . 2 . | . 6 . | . 9 . # . 3 . | . 1 . | 4 . . #
# 7 . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | 1 . . | 1 . . # . . . | . . . | . . . # . 2 . | . 2 . | . 2 . #
# 4 . 6 | 4 . 6 | 4 . 6 # . 3 . | . 8 . | . 5 . # . . . | . . . | 4 . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # 7 . . | . . 9 | 7 . 9 #
#=======================================================================#
"
)

(add-methods-help 'n-tuples
"tuples(n国同盟)。
n=2の場合がpair、n=3の場合がtriple,...。

hidden tuples:
行・列またはブロック内で[n]種の候補を含むセルが[n]カ所あり、他のセルにはその[n]種の候補が存在しないのであれば、それらのセルにはその[n]種の候補以外は存在できない。==>他候補を削除。

hidden-tuples適用後のセルには必ずnaked-tuplesを適用できる。

naked tuples:
行・列またはブロック内で[n]コの候補だけからなるセルが[n]カ所あれば、この[n]コの候補は、この[n]カ所のセル以外には存在できない。==>セル内の他候補を削除できる。

例：ブロック[5]の(3 4 9)=[G]に対して3国同盟が成立しています。
  ==> [X]の位置から候補を削除できます。
#=======================================================================#
# . . . | . . . | 1 . . # . . . | 1 . . | . . . # 1 . . | 1 . . | . . . #
# . 5 . | . 4 . | . . 6 # . 2 . | . . . | . . . # . . . | . . 6 | . 3 . #
# . . . | . . . | 7 8 . # . . . | 7 . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | 1 . . # 1 . 3 | 1 . 3 | . . 3 # 1 . . | 1 . . | . . . #
# . . . | . 2 . | . . 6 # . 5 . | . 5 . | . 5 . # 4 5 . | 4 5 6 | . 7 . #
# . 8 . | . . . | . 8 . # . 8 9 | . . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | 1 . 3 | . . . # . . . | 1 . 3 | . . . # . . . | . . . | 1 . . #
# . . . | . . . | . 9 . # . 4 . | . 5 . | . 6 . # . 8 . | . 2 . | . 5 . #
# 7 . . | 7 . . | . . . # . . . | 7 . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . G # . . 3 | . . . | . . . #
# . 1 . | . 6 . | . 2 . # . 7 . | . 8 . | G X . # 4 5 . | . 9 . | 4 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # 1 . . | 1 . . | . . . # . . . | . . . | . . . #
# . 4 . | . 9 . | . 3 . # . 5 . | . 5 . | . 2 . # . 7 . | . 8 . | . 6 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # X . G | . . . | . . G # 1 . 3 | 1 . . | . . . #
# . . . | . 5 . | . . . # . . . | . 6 . | G . . # 4 . . | 4 . . | . 2 . #
# 7 8 . | . . . | 7 8 . # . . G | . . . | . . G # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . 3 | . . . # . . 3 | . . . | . . . # . . . | . . . | . . . #
# . 9 . | . . . | . 4 . # . 5 . | . 2 . | . 1 . # . 6 . | . 7 . | . 5 . #
# . . . | . 8 . | . . . # . 8 . | . . . | . . . # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . . # . . . | . . . | . . . # 1 . . | . . . | 1 . . #
# . 2 . | . . . | . 5 . # . 6 . | 4 5 . | 4 5 . # 4 5 . | . 3 . | 4 5 . #
# . . . | 7 8 . | 7 8 . # . . . | . . 9 | . 8 9 # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . 3 | 1 . . # . . 3 | . . 3 | . . . # . . . | 1 . . | . . . #
# . 6 . | . . . | . 5 . # . 5 . | 4 5 . | . 7 . # . 2 . | 4 5 . | . 9 . #
# . . . | . 8 . | . 8 . # . 8 . | . . . | . . . # . . . | . . . | . . . #
#=======================================================================#
"
)

(add-methods-help 'localization
"Localization(=Locked Candidates)

ブロック内の候補セルが行または列方向だけに直線的に並んでいる場合、並んでいる行または列内の他候補から並んでいる候補を削除できる。[n-grid]も参照。

例：[G]=[1]は5行目ではブロック4にのみ存在します。つまり5行目では[G]のうちのどちらかが必ず[1]です。
  ==> ブロック内の他の[1]=[X]を削除できます。
#=======================================================================#
# 1 2 . | 1 . . | 1 . . # . . . | . . . | . 2 . # . 2 . | . 2 . | . 2 . #
# 4 5 6 | 4 . 6 | 4 . 6 # . 7 . | . 3 . | 4 . 6 # . 5 6 | . . . | . . 6 #
# . . . | . . 9 | . . . # . . . | . . . | . . . # . . . | . 8 9 | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . 2 . # . . . | . . . | . 2 . #
# . 5 6 | . 3 . | . 7 . # . 8 . | . 5 . | . . 6 # . 1 . | . 4 . | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . . . # . 2 . | . . . | . 2 3 #
# 4 5 6 | . 8 . | 4 . 6 # . 9 . | 4 5 . | . 1 . # . 5 6 | . 7 . | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# X . . | X . . | . . . # . . . | . 2 . | . . . # . . . | . 2 3 | 1 2 3 #
# 4 . . | 4 . . | . 5 . # . 6 . | 4 . . | . 8 . # . 9 . | . . . | . . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | G . . | G . 3 # . . . | . . . | . 2 . # . 2 . | . 2 3 | . . . #
# . 9 . | 4 . 6 | 4 . 6 # . 5 . | . 7 . | 4 . . # . . 6 | . . . | . 8 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . . 6 | . . 6 | . 2 . # . 1 . | . 9 . | . 3 . # . 4 . | . 5 . | . . 6 #
# 7 8 . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . 3 . | . 2 . | . 9 . # . 4 . | . 1 . | . 7 . # . 8 . | . 6 . | . 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# 4 . . | . 5 . | . 8 . # . 2 . | . 6 . | . 9 . # . 3 . | . 1 . | 4 . . #
# 7 . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | 1 . . | 1 . . # . . . | . . . | . . . # . 2 . | . 2 . | . 2 . #
# 4 . 6 | 4 . 6 | 4 . 6 # . 3 . | . 8 . | . 5 . # . . . | . . . | 4 . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # 7 . . | . . 9 | 7 . 9 #
#=======================================================================#
"
)

(add-methods-help 'n-grid
"グリッド解析(n-grid)

グリッド解析はWing系手筋を一般化した手筋。

[定理] 領域[A]と領域[B]の共通領域に候補[k]が存在し共通領域以外の領域[A]に候補[k]が存在しないならば、共通領域以外の領域[B]にも候補[k]は存在しない。==> 候補一覧から削除して良い。

領域[A]と領域[B]の種類によって以下の手筋に相当。グリッド解析はx-wing,swordfish等を一般化した関数でそれらを含む。

localizationとtuplesは別関数として実装。singlesはtuplesに含めた。

method          領域A 領域B 候補
------------------------------------------
singles         row_1   col_1   k_1
                col_1   row_1   k_1
                block_1 cell_1  k_1
localization    block_1 row_1   k_1
                block_1 col_1   k_1
tuples          row_1   col_n   k_n
                col_1   row_n   k_n
                block_1 cell_n  k_n
x-wing          row_2   col_2   k_1
swordfish       row_3   col_3   k_1
jellyfish       row_4   col_4   k_1
squirmbag       row_5   col_5   k_1
whale           row_6   col_6   k_1
leviathan       row_7   col_7   k_1
n-grid          row_n   col_n   k_1
------------------------------------------
Note : アンダースコア \"\_\" に続く数字は個数を表わしている。

See http://www.stolaf.edu/people/hansonr/sudoku/explain.htm

例：候補[5]に対して行方向にswordfish(3x3)=[B]が成立しています。
[X]の位置から[5]を削除できます。
#=======================================================================#
# . . . | . . . | 1 . . # . . . | 1 . . | . . . # 1 . . | 1 . . | . . . #
# . 5 . | . 4 . | . . 6 # . 2 . | . . . | . . . # . . . | . . 6 | . 3 . #
# . . . | . . . | 7 8 . # . . . | 7 . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | 1 . . # 1 . 3 | 1 . 3 | . . 3 # 1 . . | 1 . . | . . . #
# . . . | . 2 . | . . 6 # . X . | . X . | . 5 . # 4 5 . | 4 5 6 | . 7 . #
# . 8 . | . . . | . 8 . # . 8 9 | . . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | 1 . 3 | . . . # . . . | B . B | . . . # . . . | . . . | B . . #
# . . . | . . . | . 9 . # . 4 . | . B . | . 6 . # . 8 . | . 2 . | . B . #
# 7 . . | 7 . . | . . . # . . . | B . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . 3 # . . 3 | . . . | . . . #
# . 1 . | . 6 . | . 2 . # . 7 . | . 8 . | 4 5 . # 4 5 . | . 9 . | 4 X . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # B . . | B . . | . . . # . . . | . . . | . . . #
# . 4 . | . 9 . | . 3 . # . B . | . B . | . 2 . # . 7 . | . 8 . | . 6 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # 1 . 3 | . . . | . . 3 # 1 . 3 | 1 . . | . . . #
# . . . | . 5 . | . . . # . . . | . 6 . | 4 . . # 4 . . | 4 . . | . 2 . #
# 7 8 . | . . . | 7 8 . # . . 9 | . . . | . . 9 # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . 3 | . . . # . . B | . . . | . . . # . . . | . . . | . . . #
# . 9 . | . . . | . 4 . # . B . | . 2 . | . 1 . # . 6 . | . 7 . | . B . #
# . . . | . 8 . | . . . # . B . | . . . | . . . # . . . | . . . | . B . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . . # . . . | . . . | . . . # 1 . . | . . . | 1 . . #
# . 2 . | . . . | . 5 . # . 6 . | 4 X . | 4 5 . # 4 5 . | . 3 . | 4 X . #
# . . . | 7 8 . | 7 8 . # . . . | . . 9 | . 8 9 # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . 3 | 1 . . # . . 3 | . . 3 | . . . # . . . | 1 . . | . . . #
# . 6 . | . . . | . 5 . # . X . | 4 X . | . 7 . # . 2 . | 4 5 . | . 9 . #
# . . . | . 8 . | . 8 . # . 8 . | . . . | . . . # . . . | . . . | . . . #
#=======================================================================#
"
)

(add-methods-help 'pattern-overlay-method
"配置確定法(Pattern Overlay Method)

候補が存在する可能性がある位置を示した表[check-board]から、ナンプレのルール下であり得る存在パターンを特定し候補位置を絞り込む。

ある位置の候補を仮定した場合、各ブロック／行／列内に存在していた候補がすべて消えてしまう場合は仮定が誤り。
矛盾が発生するパターンは廃棄。

すべてのパターンに共通する存在可能位置があれば確定値。
すべてのパターンに現れない位置があれば候補を削除可能。

例：以下の盤面に対して候補数字「1」が存在するセルを「*」で表わすと

#=======================================================================#
# 1 2 . | 1 . . | 1 . . # . . . | . . . | . 2 . # . 2 . | . 2 . | . 2 . #
# 4 5 6 | 4 . 6 | 4 . 6 # . 7 . | . 3 . | 4 . 6 # . 5 6 | . . . | . . 6 #
# . . . | . . 9 | . . . # . . . | . . . | . . . # . . . | . 8 9 | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . 2 . # . . . | . . . | . 2 . #
# . 5 6 | . 3 . | . 7 . # . 8 . | . 5 . | . . 6 # . 1 . | . 4 . | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . . . # . 2 . | . . . | . 2 3 #
# 4 5 6 | . 8 . | 4 . 6 # . 9 . | 4 5 . | . 1 . # . 5 6 | . 7 . | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# 1 . . | 1 . . | . . . # . . . | . 2 . | . . . # . . . | . 2 3 | 1 2 3 #
# 4 . . | 4 . . | . 5 . # . 6 . | 4 . . | . 8 . # . 9 . | . . . | . . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . 3 # . . . | . . . | . 2 . # . 2 . | . 2 3 | . . . #
# . 9 . | 4 . 6 | 4 . 6 # . 5 . | . 7 . | 4 . . # . . 6 | . . . | . 8 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . . 6 | . . 6 | . 2 . # . 1 . | . 9 . | . 3 . # . 4 . | . 5 . | . . 6 #
# 7 8 . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . 3 . | . 2 . | . 9 . # . 4 . | . 1 . | . 7 . # . 8 . | . 6 . | . 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# 4 . . | . 5 . | . 8 . # . 2 . | . 6 . | . 9 . # . 3 . | . 1 . | 4 . . #
# 7 . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | 1 . . | 1 . . # . . . | . . . | . . . # . 2 . | . 2 . | . 2 . #
# 4 . 6 | 4 . 6 | 4 . 6 # . 3 . | . 8 . | . 5 . # . . . | . . . | 4 . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # 7 . . | . . 9 | 7 . 9 #
#=======================================================================#

こうなります。
+-------+-------+-------+
| * * * | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| * * - | - - - | - - * |
| - * * | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| * * * | - - - | - - - |
+-------+-------+-------+

同じ行・列・ブロックにはナンプレのルール上、同じ候補数字はひとつだけしか存在できないので、存在可能なパターンは限られます。
その存在可能な配置パターンは上の場合は次の4通りだけです。
パターン 1
+-------+-------+-------+
| * - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - * |
| - * - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - * | - - - | - - - |
+-------+-------+-------+
パターン 2
+-------+-------+-------+
| * - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - * |
| - - * | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - * - | - - - | - - - |
+-------+-------+-------+
パターン 3
+-------+-------+-------+
| - * - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - * |
| - - * | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| * - - | - - - | - - - |
+-------+-------+-------+
パターン 4
+-------+-------+-------+
| - - * | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - * |
| - * - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| * - - | - - - | - - - |
+-------+-------+-------+

上記の全ての可能な配置パターンで共通して候補数字が存在するのは唯一4行9列だけです。

+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - * |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+

候補数字「1」が4行9列に存在しないのであればナンプレのルール上有効な配置パターンが全く存在しないことになり矛盾です。
従って4行9列の候補数字「1」は確定値です。

その結果、同じ行・列・ブロックに存在する4行1列と4行2列の「1」も削除できます。

+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| * * - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+

上記の例では現れませんでしたが、ナンプレのルール上有効な配置パターンのどこにも現れない候補数字位置があれば、
その位置の候補数字は削除できることになります。
"
)

(add-help 'cell-expression
"「セル式」とはrow,col,cell,block,house,chain,candidate,determinedを構文要素として
and,or,notで構成される論理式のことです。条件に一致するセル・アドレスのリストを返します。

(or (row 3 5) (col 3 6)) と記述することで3行目と5行目、および3列目と6列目すべてのセルを表します。
(and (row 3 5) (col 3 6)) と記述すると3行目と5行目、および3列目と6列目の4つの交点のセルを表します。
(house (3 5)) は3行5列のセルを含むハウス全体のセルを表します。

この論理式は以下の文法に従って自由に記述できます。

[and]   ::= (and [exp]*) ; 
[or]    ::= (or  [exp]*) ;
[not]   ::= (not [exp]*) = (not (or [exp-1] [exp-2]...[exp-n])) ;

[exp]   ::= ({and | or | not} [exp]*) | [cell] | [row] | [col] | [cell] | [block] | [chain] | [house] ;

[row]   ::= (row [i-exp]+) ;
[col]   ::= (col [i-exp]+) ;
[cell]  ::= (cell [exp]+) ;
[block] ::= (block [i-exp]+) ;
[chain] ::= (chain [exp]+) ;
[house] ::= (house [address]) ;
[address] ::= ([integer] [integer]) ;
[candidate]  ::= ({cand|candidate}) | ({cand|candidate} {[i-exp]* | ([i-exp]+)}) ;
[determined] ::= ({det|determined}) | ({det|determined} {[i-exp]* | ([i-exp]+)}) ;
[i-exp] ::= 結果が整数となる式 ;

(not) は全てのセル・アドレスを表わす。
(and) は空のセル・アドレスを表わす(一致するセル・アドレスなし)。
(or)  は空のセル・アドレスを表わす(一致するセル・アドレスなし)。

* [candidate]式は指定された候補数字を含むセル・アドレスを返す。複数の候補数字が指定された場合は全ての候補数字を
含むセル・アドレスを返す。

(candidate)                          は確定値でない全てのセル・アドレスを返す。
(candidate (1 4))                    は候補数字1と4の両方を含むセル・アドレスを返す。
(or (candidate (1)) (candidate (4))) は候補数字1か4のいずれか、または両方を含むセル・アドレスを返す。

* [determined]式は指定されたセル・アドレスの内、確定値であるセル・アドレスを返す。

(determined)                      は全ての確定値のセル・アドレスを返す。
(determined (3 7))                は確定値が3か7である全てのセル・アドレスを返す。
(or (determined 3) (detemined 7)) は上の式と同じ意味。

Notice. [s*]は直前の[s]のゼロ回以上の繰り返し、[s+]は直前の[s]の1回以上の繰り返し。「{A|B}」は「AかB」のどちらか一方。
"
)

(add-help 'menu
"盤面検討用関数[examin]のメニューの説明です。メニュー項目の表示は\"Menu\"コマンドにより4段階から選択できます。

        Verboseモード        一番多くのメニュー項目を表示するモード。説明も多い。
        Normalモード よく使うメニュー項目だけを表示するモード。
        Mimimumモード        必要最小限のメニュー項目だけを表示するモード。
        Commandモード        一切のメニュー項目を表示しない慣れた人用のモード。

表示されていないメニュー項目も表示されていないだけで、すべてのモードでVerboseモードと同じ、すべてのメニュー項目を選択できます。

メニュー項目を選択するには、メニュー項目の\")\"または\"]\"より前の部分の「短縮名」を入力するか、\")\"または\"]\"を除いた先頭単語全体を入力します。例えば表示する盤面のサイズを変更する\"B\)oard\"メニューの場合、先頭の\"b\"だけを入力するか\")\"を除いた\"board\"と入力するかの2択です。大文字・小文字の区別はありません。\"Board\"でも\"bOaRd\"でも構いません。

2つ以上の単語が並んでいる場合は先頭の単語のみが対象です。例えば\"A\]uto save\"メニューの場合、先頭の\"A\"だけを入力するか\"\]\"を除いた\"Auto\"と入力します。\"Autosave\"では\"auto\"コマンドと認識しません。この場合も\"a\"と小文字でも構いませんし、\"auto\"や\"Auto\"でも構いません。

メニュー項目の「コマンド名」を覚えてきたらメニュー項目の表示量の少ないモードを選ぶと、各モードの実行結果を表示するスペースを多く取れます。

メニュー項目の単語途中のカッコは\"\)\"と\"\]\"の2種類があります。カッコより前が短縮名という意味では同じですが、\"\]\"の場合は表示するメッセージ量が少ないので、出力後にメニュー全体を再表示しません。
"
  )

(add-help 'examin
"ナンプレの各盤面に対して(設定した手筋と制限の範囲で)適用可能なすべての手筋を表示し、ユーザが選択的に手を進めるための関数です。メニュー形式で検討を進めます。

メニュー行頭に\"+\"が表示されているコマンドは (allow-explore t) と設定した場合に表示されます。ホーム・ディレクトリに NumberPlace-init.lisp というファイルがあると、初期設定ファイルとして NumberPlace.lisp 起動時に自動的に読み込まれます。通常は、この初期設定ファイルに各種初期設定を書き込んでおきます。

盤面には[ノード番号]という一意な番号が振られ、任意の番号に手を戻すことが出来ます。得られた解法経路情報は \"Save\" コマンドでファイルに書き出して保存することが出来ます。

解法ルート[1] : #0 --(基本手筋)--> #1(finished)
解法ルート[12] : #0 --(配置確定法)--> #2 --(基本手筋)--> #12(finished)
解法ルート[14] : #0 --(配置確定法)--> #2 --(単独候補)--> #14(finished)
解法ルート[16] : #0 --(配置確定法)--> #2 --(ローカライゼーション)--> #16(finished)
解法ルート[17] : #0 --(配置確定法)--> #2 --(n国同盟)--> #17(finished)
解法ルート[18] : #0 --(配置確定法)--> #2 --(nグリッド)--> #18(finished)
解法ルート[19] : #0 --(配置確定法)--> #2 --(Almost Locked Set)--> #19(finished)
解法ルート[20] : #0 --(配置確定法)--> #2 --(Grid Based Almost Locked Set)--> #20(finished)
解法ルート[21] : #0 --(配置確定法)--> #2 --(Advanced Coloring)--> #21(finished)
解法ルート[3] : #0 --(単独候補)--> #3(finished)
解法ルート[5] : #0 --(ローカライゼーション)--> #5(finished)
解法ルート[6] : #0 --(n国同盟)--> #6(finished)
解法ルート[7] : #0 --(nグリッド)--> #7(finished)
解法ルート[8] : #0 --(Almost Locked Set)--> #8(finished)
解法ルート[9] : #0 --(Grid Based Almost Locked Set)--> #9(applied)
解法ルート[10] : #0 --(Advanced Coloring)--> #10(finished)

上の例の、2行目の \"解法ルート\[12\]\" はルート・ノード(=ノード番号\#0)から配置確定法でノード番号\#2の盤面が得られ、そこから基本手筋でノード番号\#12の盤面に至り \"finished\" 、つまり解が得られた終了状態という意味です。\"applied\"は手筋は適用できたが解が得られてはいない途中盤面という意味です。

メニューから \"Description\" コマンドを選び、ノード番号(数字のみ)を入力すると、そのノード番号に至る解き筋の解法に対する解説盤面が表示されます。

\"Find\"コマンドで検討したい盤面の番号を選び、\"Methods\"コマンドで適用可能な手筋を表示させ、更に同様の手順で検討を進めるのが一般的な手順です。\"Find\"コマンドで過去の盤面に戻り、別のルートを検討することも出来ます。
")

(add-methods-help 'almost-locked-set
"Almost Locked Set

[定義] Almost Locked Setとは n+1個の候補数字が n個のセルに配置されているセルの集合である。

[定理1] ２つのAlmost Locked Set同士の間に2つのlinkが存在するならば、双方の集団内のすべての候補数字[k]を見ることができる位置にある候補数字[k]は削除できる。

[定理２] ２つのAlmost Locked Setが候補数字[i]を介してlinkしており、[i]とは異なる共通の候補数字[k]が存在するならば、２つのAlmost Locked Set内のすべての[k]を「見ることができる」位置にあるAlmost Locked Setの要素でない[k]は削除できる。

詳しくは添付のpdfファイル[Almost Locked Set入門]を参照。

例：Almost Locked Setにより[X]の位置から候補を削除できます。
r6c1,r6c3,r6c8の候補数字はAlmost Locked Set [A]=(1 4 7 8)を構成しています。
r4c7,r4c9,r6c7の候補数字はAlmost Locked Set [B]=(1 3 4 5)を構成しています。
Almost Locked Set[A]と[B]は候補数字(1 4)により相互にリンクしています。
  ==> r6c4の[1]はAlmost Locked Set内のすべての[1]を見ることができるので削除できます。
  ==> r4c6の[5]はAlmost Locked Set内のすべての[5]を見ることができるので削除できます。
#=======================================================================#
# . . . | . . . | 1 . . # . . . | 1 . . | . . . # 1 . . | 1 . . | . . . #
# . 5 . | . 4 . | . . 6 # . 2 . | . . . | . . . # . . . | . . 6 | . 3 . #
# . . . | . . . | 7 8 . # . . . | 7 . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | 1 . . # 1 . 3 | 1 . 3 | . . 3 # 1 . . | 1 . . | . . . #
# . . . | . 2 . | . . 6 # . 5 . | . 5 . | . 5 . # 4 5 . | 4 5 6 | . 7 . #
# . 8 . | . . . | . 8 . # . 8 9 | . . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | 1 . 3 | . . . # . . . | 1 . 3 | . . . # . . . | . . . | 1 . . #
# . . . | . . . | . 9 . # . 4 . | . 5 . | . 6 . # . 8 . | . 2 . | . 5 . #
# 7 . . | 7 . . | . . . # . . . | 7 . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . 3 # . . G | . . . | . . . #
# . 1 . | . 6 . | . 2 . # . 7 . | . 8 . | 4 X . # G G . | . 9 . | G G . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # 1 . . | 1 . . | . . . # . . . | . . . | . . . #
# . 4 . | . 9 . | . 3 . # . 5 . | . 5 . | . 2 . # . 7 . | . 8 . | . 6 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # X . 3 | . . . | . . 3 # G . G | B . . | . . . #
# . . . | . 5 . | . . . # . . . | . 6 . | 4 . . # G . . | B . . | . 2 . #
# B B . | . . . | B B . # . . 9 | . . . | . . 9 # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . 3 | . . . # . . 3 | . . . | . . . # . . . | . . . | . . . #
# . 9 . | . . . | . 4 . # . 5 . | . 2 . | . 1 . # . 6 . | . 7 . | . 5 . #
# . . . | . 8 . | . . . # . 8 . | . . . | . . . # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . . # . . . | . . . | . . . # 1 . . | . . . | 1 . . #
# . 2 . | . . . | . 5 . # . 6 . | 4 5 . | 4 5 . # 4 5 . | . 3 . | 4 5 . #
# . . . | 7 8 . | 7 8 . # . . . | . . 9 | . 8 9 # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . 3 | 1 . . # . . 3 | . . 3 | . . . # . . . | 1 . . | . . . #
# . 6 . | . . . | . 5 . # . 5 . | 4 5 . | . 7 . # . 2 . | 4 5 . | . 9 . #
# . . . | . 8 . | . 8 . # . 8 . | . . . | . . . # . . . | . . . | . . . #
#=======================================================================#
")

(add-methods-help 'grid-based-almost-locked-set
"Grid-Based Almost Locked Set(GB-ALS)

Grid-Based Almost Locked Set(GB-ALS)は同じ値の候補数字が n 列（行）には n 個以上存在しなければならないという原理を利用して削除可能な候補を探索する手筋です。

通常の ALS が候補数字（値）をベースとした Almost Locked Set を利用するのに対して盤面を n 行 n 列の格子（Grid）として格子上での位置情報をベースとした Almost Locked Set を利用するので GB-ALS と呼ばれます。

GB-ALS は Sashimi 系手筋 \(Sashimi X-Wing,Sashimi Swordfish,Sashimi Jellyfish など\)を一般化したもので Sashimi 系のすべての手筋は GB-ALS として説明可能です。

定理 ： n カ所の列（または行）内の候補数字 p が n+1 カ所の行（または列）に存在するとき、これらの要素でないあるセルｘに p を仮定すると、 n 個の列（または行）の候補数字 p が n-1 カ所以下の行（または列）にしか存在できなくなるならば、セルｘの候補数字ｐを削除できる 。

詳しくは添付のpdfファイル[GB-ALS入門]を参照。

例： Grid-Based Almost Locked Setにより[X]の位置から候補を削除できます。
[B]は[5]に関して行方向のGrid-Based ALSを構成しています。
r9c5に[5]が存在するとr5c4が行内での確定値となりGB-ALSの2行のうち1列にしか[5]が存在できないので矛盾です。
  ==> r9c5,r9c5,r9c4,r8c5,r8c5,r2c5,r2c4,r2c4<>5
r9c5に[5]が存在するとGB-ALSの2行のうち1列にしか[5]が存在できないので矛盾です。
  ==> r9c5,r9c5,r9c4,r8c5,r8c5,r2c5,r2c4,r2c4<>5
r9c4に[5]が存在するとr5c5が行内での確定値となりGB-ALSの2行のうち1列にしか[5]が存在できないので矛盾です。
  ==> r9c5,r9c5,r9c4,r8c5,r8c5,r2c5,r2c4,r2c4<>5
r8c5に[5]が存在するとr5c4が行内での確定値となりGB-ALSの2行のうち1列にしか[5]が存在できないので矛盾です。
  ==> r9c5,r9c5,r9c4,r8c5,r8c5,r2c5,r2c4,r2c4<>5
r8c5に[5]が存在するとGB-ALSの2行のうち1列にしか[5]が存在できないので矛盾です。
  ==> r9c5,r9c5,r9c4,r8c5,r8c5,r2c5,r2c4,r2c4<>5
r2c5に[5]が存在するとr5c4が行内での確定値となりGB-ALSの2行のうち1列にしか[5]が存在できないので矛盾です。
  ==> r9c5,r9c5,r9c4,r8c5,r8c5,r2c5,r2c4,r2c4<>5
r2c4に[5]が存在するとr5c5が行内での確定値となりGB-ALSの2行のうち1列にしか[5]が存在できないので矛盾です。
  ==> r9c5,r9c5,r9c4,r8c5,r8c5,r2c5,r2c4,r2c4<>5
r2c4に[5]が存在するとGB-ALSの2行のうち1列にしか[5]が存在できないので矛盾です。
  ==> r9c5,r9c5,r9c4,r8c5,r8c5,r2c5,r2c4,r2c4<>5
#=======================================================================#
# . . . | . . . | 1 . . # . . . | 1 . . | . . . # 1 . . | 1 . . | . . . #
# . 5 . | . 4 . | . . 6 # . 2 . | . . . | . . . # . . . | . . 6 | . 3 . #
# . . . | . . . | 7 8 . # . . . | 7 . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | 1 . . # 1 . 3 | 1 . 3 | . . 3 # 1 . . | 1 . . | . . . #
# . . . | . 2 . | . . 6 # . X . | . X . | . 5 . # 4 5 . | 4 5 6 | . 7 . #
# . 8 . | . . . | . 8 . # . 8 9 | . . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | 1 . 3 | . . . # . . . | B . B | . . . # . . . | . . . | B . . #
# . . . | . . . | . 9 . # . 4 . | . B . | . 6 . # . 8 . | . 2 . | . B . #
# 7 . . | 7 . . | . . . # . . . | B . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . 3 # . . 3 | . . . | . . . #
# . 1 . | . 6 . | . 2 . # . 7 . | . 8 . | 4 5 . # 4 5 . | . 9 . | 4 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # Y . . | Y . . | . . . # . . . | . . . | . . . #
# . 4 . | . 9 . | . 3 . # . Y . | . Y . | . 2 . # . 7 . | . 8 . | . 6 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # 1 . 3 | . . . | . . 3 # 1 . 3 | 1 . . | . . . #
# . . . | . 5 . | . . . # . . . | . 6 . | 4 . . # 4 . . | 4 . . | . 2 . #
# 7 8 . | . . . | 7 8 . # . . 9 | . . . | . . 9 # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . 3 | . . . # . . B | . . . | . . . # . . . | . . . | . . . #
# . 9 . | . . . | . 4 . # . B . | . 2 . | . 1 . # . 6 . | . 7 . | . B . #
# . . . | . 8 . | . . . # . B . | . . . | . . . # . . . | . . . | . B . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . . # . . . | . . . | . . . # 1 . . | . . . | 1 . . #
# . 2 . | . . . | . 5 . # . 6 . | 4 X . | 4 5 . # 4 5 . | . 3 . | 4 5 . #
# . . . | 7 8 . | 7 8 . # . . . | . . 9 | . 8 9 # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . 3 | 1 . . # . . 3 | . . 3 | . . . # . . . | 1 . . | . . . #
# . 6 . | . . . | . 5 . # . X . | 4 X . | . 7 . # . 2 . | 4 5 . | . 9 . #
# . . . | . 8 . | . 8 . # . 8 . | . . . | . . . # . . . | . . . | . . . #
#=======================================================================#
"
)

(add-methods-help 'advanced-coloring
"Advanced Coloring

Advanced Coloring は 3D Medusa とも呼ばれる、複数の候補数字を対象としたグラフ彩色手法です。

(rule\#1) ひとつのセル内の2つの異なる候補数字が同じ色で塗り分けられている。
(rule\#2) 同じグループ(ユニット)に属する同じ数字に対する2つの候補数字が同じ色に彩色されている。
(rule\#3) 未確定の値を持つセル内に2つの異なる色が存在する。
(rule\#4) ある数字に対して複数の候補数字が存在するグループで、その数字に対して異なる色で彩色された色が2つある。
(rule\#5) 彩色されている数字のグループに属すセルであって、そのセルのグループに「反対の色」で彩色された同じ値の候補数字が存在する。
(rule\#6) 彩色されていない候補数字と同じグループ内に同じ値の彩色された候補数字(a)が存在し、彩色されていない候補数字と同じセルに(a)と反対の色に彩色された候補数字が存在する。

(rule\#1),(rule\#2) = 矛盾が発生している色に彩色されている候補数字すべてを削除できる。
(rule\#3),(rule\#4) = 塗り分けられていない候補数字を削除できる。
(rule\#5),(rule\#6) = (#5)両方の色を同時に見ることができる候補数字を削除できる。
                      (#6)彩色されていない候補数字を削除できる。

詳しくは添付のpdfファイル[3D Medusa(翻訳)]を参照。

例：
coloring for 1, cluster #1
#=======================================================================#
# . . . | . . . | 1 . . # . . . | 1 . . | . . . # 1 . . | 1 . . | . . . #
# . 5 . | . 4 . | . . 6 # . 2 . | . . . | . . . # . . . | . . 6 | . 3 . #
# . . . | . . . | 7 8 . # . . . | 7 . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | 1 . . # 1 . 3 | 1 . 3 | . . 3 # 1 . . | 1 . . | . . . #
# . . . | . 2 . | . . 6 # . 5 . | . 5 . | . 5 . # 4 5 . | 4 5 6 | . 7 . #
# . 8 . | . . . | . 8 . # . 8 9 | . . 9 | . 8 9 # . . 9 | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | 1 . 3 | . . . # . . . | 1 . 3 | . . . # . . . | . . . | 1 . . #
# . . . | . . . | . 9 . # . 4 . | . 5 . | . 6 . # . 8 . | . 2 . | . 5 . #
# 7 . . | 7 . . | . . . # . . . | 7 . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . 3 # . . 3 | . . . | . . . #
# . 1 . | . 6 . | . 2 . # . 7 . | . 8 . | 4 X . # 4 5 . | . 9 . | 4 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # G . . | B . . | . . . # . . . | . . . | . . . #
# . 4 . | . 9 . | . 3 . # . B . | . G . | . 2 . # . 7 . | . 8 . | . 6 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # 1 . 3 | . . . | . . 3 # 1 . 3 | 1 . . | . . . #
# . . . | . 5 . | . . . # . . . | . 6 . | 4 . . # 4 . . | 4 . . | . 2 . #
# 7 8 . | . . . | 7 8 . # . . 9 | . . . | . . 9 # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | . . 3 | . . . # . . 3 | . . . | . . . # . . . | . . . | . . . #
# . 9 . | . . . | . 4 . # . 5 . | . 2 . | . 1 . # . 6 . | . 7 . | . 5 . #
# . . . | . 8 . | . . . # . 8 . | . . . | . . . # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . . # . . . | . . . | . . . # 1 . . | . . . | 1 . . #
# . 2 . | . . . | . 5 . # . 6 . | 4 5 . | 4 5 . # 4 5 . | . 3 . | 4 5 . #
# . . . | 7 8 . | 7 8 . # . . . | . . 9 | . 8 9 # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . 3 | 1 . . # . . 3 | . . 3 | . . . # . . . | 1 . . | . . . #
# . 6 . | . . . | . 5 . # . 5 . | 4 5 . | . 7 . # . 2 . | 4 5 . | . 9 . #
# . . . | . 8 . | . 8 . # . 8 . | . . . | . . . # . . . | . . . | . . . #
#=======================================================================#
(r#5) [r4c6]のX=5は[r5c4]のB=5と[r5c5]のG=5を同時に見ることができる位置です。
  ==> r4c6<>5
")

(add-methods-help 'nice-loop
"Nice Loop

Nice Loop は、ふたつのセル（マス）間の論理的依存関係の連鎖を利用してセルの候補数字を特定したり削除する手筋です。以下は添付のpdfファイル[Nice Loop入門]の抜粋です。

A というセルと B というセルにリンク関係が成立していて、なおかつセル B とセル C にも別のリンク関係が成立しているのであれば、A での仮定は B での結論となり、B での結論が C に対する B での仮定となり、全体として A の仮定に対する C での結論となります。

このようなリンク関係の連鎖は連鎖するセル数がいくつに増えてもやはり成り立ちます。
A → B → C → ･･･ → Z
このような連鎖の場合、A での仮定が結局 Z での結論に直結します。この連鎖関係は双方向に成り立つので、Z での仮定は A での結論に直結しています。

Nice Loop の連鎖は strong link と weak link の組合せです。そして連鎖の開始セルと終端セルが一致するような連鎖を選ぶので全体としてループを構成します。

ループを構成しているので、もし終端セル（＝開始セル）で開始セルでの仮定に矛盾する結論が導かれたとすると開始セルでの仮定が誤りだったと言うことになります。たとえば連鎖の開始セルで「4 である」と仮定して連鎖を辿ると終端セル（=開始セル）で「4 でない」という結論が導かれたとすると、最初の「４である」という仮定に誤りがあったということです（数学的な意味での背理法）。つまり開始セルに４が含まれることはあり得ないので４を削除できます。

Nice loop が成立している場合、以下の定理が成立します

定理１：
連続的nice loop内の２つのリンクが共にstrong inferenceであるセルXに対し、
それらのリンクのラベルがAとB(A≠B)であるならば、セルXにはAとB以外の数字候補は存在できない。
 
定理２：
連続的nice loop内の２つのセル間のリンクがweak inferenceであるならば、
そのリンクのラベルと同じ値の数字候補は、その２つのセルのどちらかに存在しなければならない。
したがって、リンク・ラベルの表す数字候補を２つのセルが属すユニットから削除できる。

定理３：
不連続nice loop内の不連続点であるセルXに対する２つのリンクが共にstrong inferenceであり
ラベルが共にAであるならば、セルXの値はAである。
 
定理４：
不連続nice loop内の不連続点であるセルXに対する２つのリンクが共にweak inferenceであり
ラベルが共にAであるならば、セルXから数字候補Aを削除できる。
 
定理５：
不連続nice loop内の不連続点であるセルXに対する２つのリンクがstrong inferenceと
weak inferenceであり、weak inferenceのラベルがAであるならば、セルXから数字候補Aを削除できる。

例：ひとつの盤面に以下の複数のNice Loopが成立しています。

*) Nice Loop連鎖説明中の\"=\"はStrong inference, \"-\"はWeak inferenceを表します。
   \"=\"または\"-\"に挟まれた数字はリンク数字です。

#=======================================================================#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . 7 . | . 5 . | . 1 . # . 2 . | . 3 . | . 9 . # . 6 . | . 4 . | . 5 . #
# . . . | . 8 . | . . . # . . . | . . . | . . . # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . 3 | . . . # . . . | . . . | . . . # . . 3 | . . . | . . . #
# . 6 . | . . . | . 2 . # . 1 . | . 4 . | . 5 . # . . . | . . . | . 7 . #
# . . . | . 8 . | . . . # . . . | . . . | . . . # . 8 9 | . 8 9 | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | . . . # . . . | . . . | . . . # . 2 3 | . . . | . 2 . #
# . 5 . | . 4 . | . 9 . # . 8 . | . 6 . | . 7 . # . . . | . 1 . | . 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | 1 2 3 | . . 3 # . . 3 | . . . | 1 . . # . 2 . | . . . | . 2 . #
# . 4 . | . . . | . . . # . . 6 | . 5 . | . . 6 # . . . | . 7 . | . . . #
# . . . | . . . | . 8 . # . . 9 | . . . | . . . # . 8 9 | . . . | . 8 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . 2 3 | . . 3 # . . 3 | . . . | . . 3 # . 2 . | . . . | . . . #
# . 9 . | . 5 . | . 5 . # . . . | . 8 . | 4 . . # 4 . . | . 6 . | . 1 . #
# . . . | . . . | 7 . . # 7 . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | . . . | . . . # . . . | . . . | 1 . . # . . . | . . . | . . . #
# . . . | . 6 . | . . . # . . . | . 2 . | 4 . . # 4 . . | . 5 . | . 3 . #
# . 8 . | . . . | 7 8 . # 7 . 9 | . . . | . . . # . 8 9 | . . . | . . . #
#=======================#=======================#=======================#
# . . 3 | . . . | . . 3 # . . 3 | . . . | . . . # . . . | . . . | . . . #
# . 5 . | . 9 . | . 5 6 # . . 6 | . 1 . | . 8 . # . 7 . | . 2 . | . 4 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 2 . | 1 . 3 | . . 3 # . . . | . . . | . 2 3 # . . . | . . 3 | . . . #
# . . . | . . . | . . 6 # . 4 . | . 7 . | . . 6 # . 5 . | . . . | . . . #
# . 8 . | . . . | . 8 . # . . . | . . . | . . . # . . . | . 8 9 | . 8 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . . . | . 2 3 # . . . | . . 3 | . . . #
# . . . | . 7 . | . 4 . # . 5 . | . 9 . | . . . # . 1 . | . . . | . 6 . #
# . 8 . | . . . | . . . # . . . | . . . | . . . # . . . | . 8 . | . . . #
#=======================================================================#

連続的Nice Loop -[(A)r6c1]-8-[(B)r9c1]-2-[(C)r8c1]=2=[(D)r8c6]=6=[(E)r4c6]=1=[(F)r6c6]-1-[(A)r6c1]-
  ==> r8c6<>3
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - E | - - - |
| - - - | - - - | - - - |
| A - - | - - F | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| C - - | - - D | - - - |
| B - - | - - - | - - - |
+-------+-------+-------+
不連続Nice Loop  [(A)r5c2]-3-[(B)r8c2]-1-[(C)r4c2]=1=[(D)r6c1]-1-[(E)r6c6]-4-[(F)r5c6]-3-[(A)r5c2]
  ==> r5c2<>3
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - C - | - - - | - - - |
| - A - | - - F | - - - |
| D - - | - - E | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - B - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
不連続Nice Loop  [(A)r6c3]-8-[(B)r6c1]-1-[(C)r6c6]-4-[(D)r5c6]-3-[(E)r5c4]-7-[(F)r6c4]=7=[(A)r6c3]
  ==> r6c3<>8
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | E - D | - - - |
| B - A | F - C | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
不連続Nice Loop  [(A)r8c2]-3-[(B)r8c8]=3=[(C)r9c8]=8=[(D)r9c1]-8-[(E)r6c1]-1-[(F)r4c2]=1=[(A)r8c2]
  ==> r8c2<>3
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - F - | - - - | - - - |
| - - - | - - - | - - - |
| E - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - A - | - - - | - B - |
| D - - | - - - | - C - |
+-------+-------+-------+
不連続Nice Loop  [(A)r8c6]-3-[(B)r8c2]-1-[(C)r4c2]=1=[(D)r6c1]-1-[(E)r6c6]=1=[(F)r4c6]=6=[(A)r8c6]
  ==> r8c6<>3
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - C - | - - F | - - - |
| - - - | - - - | - - - |
| D - - | - - E | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - B - | - - A | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
不連続Nice Loop  [(A)r4c4]-3-[(B)r5c6]-4-[(C)r6c6]-1-[(D)r4c6]=1=[(E)r4c2]-1-[(F)r6c1]-8-[(G)r4c3]-3-[(A)r4c4]
  ==> r4c4<>3
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - E G | A - D | - - - |
| - - - | - - B | - - - |
| F - - | - - C | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
不連続Nice Loop  [(A)r8c8]-3-[(B)r8c2]-1-[(C)r4c2]=1=[(D)r6c1]-1-[(E)r6c6]-4-[(F)r5c6]-3-[(G)r9c6]=3=[(H)r9c8]-3-[(A)r8c8]
  ==> r8c8<>3
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - C - | - - - | - - - |
| - - - | - - F | - - - |
| D - - | - - E | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| - B - | - - - | - A - |
| - - - | - - G | - H - |
+-------+-------+-------+
連続的Nice Loop =[(A)r8c1]=2=[(B)r9c1]=8=[(C)r9c8]=3=[(D)r9c6]-3-[(E)r7c4]-6-[(F)r8c6]=6=[(G)r4c6]=1=[(H)r6c6]-1-[(I)r6c1]=1=[(A)r8c1]=
  ==> r8c1<>8
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - - - | - - G | - - - |
| - - - | - - - | - - - |
| I - - | - - H | - - - |
+-------+-------+-------+
| - - - | E - - | - - - |
| A - - | - - F | - - - |
| B - - | - - D | - C - |
+-------+-------+-------+
不連続Nice Loop  [(A)r5c3]-3-[(B)r5c6]-4-[(C)r6c6]-1-[(D)r4c6]-6-[(E)r8c6]=6=[(F)r7c4]-6-[(G)r4c4]=6=[(H)r4c6]=1=[(I)r4c2]-1-[(J)r6c1]-8-[(K)r4c3]-3-[(A)r5c3]
  ==> r5c3<>3
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
| - I K | G - H | - - - |
| - - A | - - B | - - - |
| J - - | - - C | - - - |
+-------+-------+-------+
| - - - | F - - | - - - |
| - - - | - - E | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
不連続Nice Loop  [(A)r6c6]=4=[(B)r5c6]-4-[(C)r5c7]-2-[(D)r4c9]=2=[(E)r3c9]=5=[(F)r1c9]-5-[(G)r1c2]=5=[(H)r3c1]=3=[(I)r2c2]-3-[(J)r8c2]-1-[(K)r8c1]=1=[(L)r6c1]-1-[(A)r6c6]
  ==> r6c6<>1
+-------+-------+-------+
| - G - | - - - | - - F |
| - I - | - - - | - - - |
| H - - | - - - | - - E |
+-------+-------+-------+
| - - - | - - - | - - D |
| - - - | - - B | C - - |
| L - - | - - A | - - - |
+-------+-------+-------+
| - - - | - - - | - - - |
| K J - | - - - | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
不連続Nice Loop  [(A)r8c1]=2=[(B)r9c1]=8=[(C)r9c8]=3=[(D)r9c6]-3-[(E)r7c4]-6-[(F)r8c6]=6=[(G)r4c6]=1=[(H)r6c6]=4=[(I)r5c6]-4-[(J)r5c7]-2-[(K)r3c7]-3-[(L)r3c1]-5-[(M)r1c2]-8-[(N)r2c2]-3-[(O)r8c2]-1-[(A)r8c1]
  ==> r8c1<>1
+-------+-------+-------+
| - M - | - - - | - - - |
| - N - | - - - | - - - |
| L - - | - - - | K - - |
+-------+-------+-------+
| - - - | - - G | - - - |
| - - - | - - I | J - - |
| - - - | - - H | - - - |
+-------+-------+-------+
| - - - | E - - | - - - |
| A O - | - - F | - - - |
| B - - | - - D | - C - |
+-------+-------+-------+
連続的Nice Loop -[(A)r5c7]-2-[(B)r4c9]=2=[(C)r3c9]-2-[(D)r3c7]-3-[(E)r3c1]-5-[(F)r3c9]=5=[(G)r1c9]-5-[(H)r1c2]-8-[(I)r2c2]-3-[(J)r3c1]-5-[(K)r7c1]=5=[(L)r7c3]=6=[(M)r7c4]-6-[(N)r8c6]=6=[(O)r4c6]=1=[(P)r6c6]=4=[(Q)r5c6]-4-[(A)r5c7]-
  ==> r7c3<>3
+-------+-------+-------+
| - H - | - - - | - - G |
| - I - | - - - | - - - |
| J - - | - - - | D - F |
+-------+-------+-------+
| - - - | - - O | - - B |
| - - - | - - Q | A - - |
| - - - | - - P | - - - |
+-------+-------+-------+
| K - L | M - - | - - - |
| - - - | - - N | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
不連続Nice Loop  [(A)r8c9]-8-[(B)r9c8]=8=[(C)r9c1]-8-[(D)r6c1]-1-[(E)r4c2]=1=[(F)r4c6]=6=[(G)r8c6]-6-[(H)r7c4]=6=[(I)r7c3]=5=[(J)r7c1]-5-[(K)r3c1]-3-[(L)r3c7]-2-[(M)r3c9]-5-[(N)r3c1]-3-[(O)r2c2]-8-[(P)r1c2]=8=[(Q)r1c9]-8-[(A)r8c9]
  ==> r8c9<>8
+-------+-------+-------+
| - P - | - - - | - - Q |
| - O - | - - - | - - - |
| N - - | - - - | L - M |
+-------+-------+-------+
| - E - | - - F | - - - |
| - - - | - - - | - - - |
| D - - | - - - | - - - |
+-------+-------+-------+
| J - I | H - - | - - - |
| - - - | - - G | - - A |
| C - - | - - - | - B - |
+-------+-------+-------+
不連続Nice Loop  [(A)r6c4]=9=[(B)r4c4]=6=[(C)r7c4]-6-[(D)r8c6]=6=[(E)r4c6]=1=[(F)r6c6]=4=[(G)r5c6]-4-[(H)r5c7]-2-[(I)r3c7]=2=[(J)r3c9]=5=[(K)r3c1]-5-[(L)r7c1]-3-[(M)r8c2]-1-[(N)r4c2]=1=[(O)r6c1]-1-[(P)r6c6]-4-[(Q)r6c7]=4=[(R)r5c7]=2=[(S)r5c2]=5=[(T)r5c3]=7=[(U)r5c4]-7-[(A)r6c4]
  ==> r6c4<>7
+-------+-------+-------+
| - - - | - - - | - - - |
| - - - | - - - | - - - |
| K - - | - - - | I - J |
+-------+-------+-------+
| - N - | B - E | - - - |
| - S T | U - G | R - - |
| O - - | A - P | Q - - |
+-------+-------+-------+
| L - - | C - - | - - - |
| - M - | - - D | - - - |
| - - - | - - - | - - - |
+-------+-------+-------+
Nice Loopにより[X]の位置から候補を削除できます。
#=======================================================================#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . 7 . | . 5 . | . 1 . # . 2 . | . 3 . | . 9 . # . 6 . | . 4 . | . 5 . #
# . . . | . 8 . | . . . # . . . | . . . | . . . # . . . | . . . | . 8 . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . 3 | . . . # . . . | . . . | . . . # . . 3 | . . . | . . . #
# . 6 . | . . . | . 2 . # . 1 . | . 4 . | . 5 . # . . . | . . . | . 7 . #
# . . . | . 8 . | . . . # . . . | . . . | . . . # . 8 9 | . 8 9 | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . 3 | . . . | . . . # . . . | . . . | . . . # . 2 3 | . . . | . 2 . #
# . 5 . | . 4 . | . 9 . # . 8 . | . 6 . | . 7 . # . . . | . 1 . | . 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# . . . | 1 2 3 | . . 3 # . . X | . . . | 1 . . # . 2 . | . . . | . 2 . #
# . 4 . | . . . | . . . # . . 6 | . 5 . | . . 6 # . . . | . 7 . | . . . #
# . . . | . . . | . 8 . # . . 9 | . . . | . . . # . 8 9 | . . . | . 8 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . 2 X | . . X # . . 3 | . . . | . . 3 # . 2 . | . . . | . . . #
# . 9 . | . 5 . | . 5 . # . . . | . 8 . | 4 . . # 4 . . | . 6 . | . 1 . #
# . . . | . . . | 7 . . # 7 . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | . . . | . . . # . . . | . . . | X . . # . . . | . . . | . . . #
# . . . | . 6 . | . . . # . . . | . 2 . | 4 . . # 4 . . | . 5 . | . 3 . #
# . 8 . | . . . | 7 X . # X . 9 | . . . | . . . # . 8 9 | . . . | . . . #
#=======================#=======================#=======================#
# . . 3 | . . . | . . X # . . 3 | . . . | . . . # . . . | . . . | . . . #
# . 5 . | . 9 . | . 5 6 # . . 6 | . 1 . | . 8 . # . 7 . | . 2 . | . 4 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# X 2 . | 1 . X | . . 3 # . . . | . . . | . 2 X # . . . | . . X | . . . #
# . . . | . . . | . . 6 # . 4 . | . 7 . | . . 6 # . 5 . | . . . | . . . #
# . X . | . . . | . 8 . # . . . | . . . | . . . # . . . | . 8 9 | . X 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . . . | . 2 3 # . . . | . . 3 | . . . #
# . . . | . 7 . | . 4 . # . 5 . | . 9 . | . . . # . 1 . | . . . | . 6 . #
# . 8 . | . . . | . . . # . . . | . . . | . . . # . . . | . 8 . | . . . #
#=======================================================================#
")

(add-help 'color-mode
"盤面出力で候補数字をカラー出力するレベルを設定する。

レベル1以上では xterm互換ターミナルが必要。

    (color-mode 0) = 彩色対象候補数字を短縮色名で出力(完全モノクロ)。
    (color-mode 1) = 彩色対象候補数字をカラーの短縮色名で出力。
    (color-mode 2) = 彩色対象候補数字をカラーで出力。

カラー情報はコピー&ペーストでは他アプリにコピーできないが出力レベル[0]または[1]で出力しておけば文字情報として色情報をコピーできる。

出力レベルが[0]または[1]の場合、Advanced Coloringの盤面をペンシルマーク形式で出力する。他の手筋の盤面出力はペンシルマークの設定に従う。ペンシルマークの設定値は変更しない。引数なしで実行すると現在のカラー出力レベルを返す。
")

(add-help 'set-parity
" Advanced Coloringでクラスタを塗り分ける際に使用する2色(パリティ色)を変更する方法。

(1) 最も簡単な方法 = 2種類のパリティ色を予め用意されている色から選ぶ方法。
      (set-parity-1)
    とすると選択できる色名の一覧が表示されるので好みの色を選び、
      (set-parity-1 \'green)
    のように実行する。もうひとつのパリティ色の設定方法も同様で
      (set-parity-2 \'blue)
    のように実行する。
      (set-parity \'green \'blue)
    のように実行すると2種類のパリティ色を同時に設定できる。同じ色を指定するとエラー。

(2) 自由に色を選択し解説盤面に表示される1文字の短縮色名も設定したい場合。

      (set-parity-color-1 46 \"G\")

のように実行する。第１引数の[46]が色を示すカラー・コード。第２引数の[\"G\"]が解説盤面で使用される1文字の短縮色名。カラー・コードは各色に対応する数値。具体的な色の割り当ては

        (print-color-sample)

と実行すると実際の色見本が表示されるので好みで決める。もうひとつのパリティ色の設定方法も同様で

      (set-parity-color-2 27 \"B\")

のように設定する。

(3) プログラム内部で使用するパリティ色の名前も指定したい場合(プログラマ向け)。
      (set-parity-color [num] [color-code] [short-name] &optional ([color-name] nil))
        [num]        ::= [*parity-colors*]の[num]番目の要素として定義する。
        [color-code] ::= 使用したい色のコード番号。(print-color-sample)を実行すると参照できる。
        [short-name] ::= 色名を表す1文字の名前。Advanced Coloringの解説盤面内で使用する。
                         文字列を指定した場合は先頭文字が指定されたものとして扱う。
        [color-name] ::= プログラム内部で使用するパリティ色の名前を指定する。
                         指定しなかった場合の既定値は \'*color-1* と \'*color-2*。
")

(add-help 'als-show-all
"(als-show-all nil) ならAlmost Locked Setのすべての手筋を表示する。
(als-show-all t)   ならAlmost Locked Setの効率的手筋のみを表示する。
(als-show-all)     と引数なしで実行すると現在の設定値を返す。

*) 効率的手筋とは、同一の候補数字を削除できる場合
  ・[single-linked]の方が[doubly-linked]よりも効率的。
  ・2つのALSのセル数の2乗の和が小さい方が効率的。
  ・より多くの候補数字を一括削除できる方が効率的。
と定義している。
")

(add-help 'als-show-stat
"(als-show-stat nil) なら統計情報を表示しない。
(als-show-stat t)   なら統計情報を表示する。
(als-show-stat)     と引数なしで実行すると現在の設定値を返す。
")

(add-help 'gb-als-show-all
" (gb-als-show-all nil) ならGB-Almost Locked Setのすべての手筋を表示する。
(gb-als-show-all t)   ならGB-Almost Locked Setの効率的手筋のみを表示する。
(gb-als-show-all)     と引数なしで実行すると現在の設定値を返す。

*) 効率的手筋とは、同一の候補数字を削除できる場合
  ・より多くの候補数字を一括削除できる方が効率的。
  ・2つのGB-ALSのセル数の2乗の和が小さい方が効率的。
と定義している。
")

(add-help 'capital-address
"セル・アドレスを大文字で表示するか小文字で表示するかを設定する。

(capital-address nil) なら小文字(ex.[r2c3])で表示する。
(capital-address t)   なら大文字(ex.[R2C3])で表示する。
(capital-address)     と引数なしで実行すると現在の設定値を返す。
")

(add-help 'need-multiple-answer
"複数解を探索するかどうかを設定する。

(need-multiple-answer t)   で複数解を探索する。
(need-multiple-answer nil) で複数解を探索しない。初期値は[t]。
")

(add-help 'print-color-sample
"関数[color-type]の設定に従って、色コードと色見本を表示する。引数はない。
(print-color-sample)で色見本が表示される。
")

(add-help 'sel
"解説盤面の種類とAdvanced Coloring画面の組み合わせを選択する。引数はない。

xterm互換端末ではD, 非互換端末ではAかBがお奨め。

A) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=モノクロ＆記号。
B) 表示=モノクロ, サイズ=標準。Advanced Coloring表示=モノクロ＆記号。
C) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=カラー  ＆記号。
D) 表示=カラー  , サイズ=標準。Advanced Coloring表示=カラー  ＆記号。
E) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=カラー  ＆数字。
F) 表示=カラー,   サイズ=標準。Advanced Coloring表示=カラー  ＆数字。

A...F: 解説盤面の種類とAdvanced Coloring画面の組み合わせを選択します。
xterm互換端末ではD, 非互換端末ではAかBがお奨めです。

A) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=モノクロ＆記号。
B) 表示=モノクロ, サイズ=標準。Advanced Coloring表示=モノクロ＆記号。
C) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=カラー  ＆記号。
D) 表示=カラー  , サイズ=標準。Advanced Coloring表示=カラー  ＆記号。
E) 表示=モノクロ, サイズ=ミニ。Advanced Coloring表示=カラー  ＆数字。
F) 表示=カラー,   サイズ=標準。Advanced Coloring表示=カラー  ＆数字。
")

#|
(add-help 'set-unique-or-series
"無名の盤面データへの記号名の与え方を決める関数。

(set-unique-or-series 0) など引数が0以上の整数なら、[prefix-name]+その整数から始まる連番。一意性は保証されない。
(set-unique-or-series t) など引数がゼロ以上の整数でないなら変数はシステム組み込み関数[gentemp]によって作成され、変数の一意性が保証される。ただし番号部はユーザ・プログラムからは制御出来ないので連番も保証されない。
")
|#

(add-help 'tuples-limit
"(tuples-limit 4)   n国同盟の上限を(この例の場合は4国同盟までに)設定する。
(tuples-limit nil) 同盟数に制限なし。

9x9のナンプレであれば4国同盟が理論上の有意最大値(5国同盟が成立するなら4国同盟が成立している)。
")

(add-help 'n-grid-limit
"グリッド解析の上限を設定する。[nil]は制限なし。

詳細は (help-for 'n-grid) で表示される n-grid のヘルプを参照。
")

(add-help 'min-nice-length
"Nice Loopとして許可する連鎖の最短長。ループを構成するには[3]以上が必要。

(min-nice-length 5) とすると連鎖数が4以下のNice Loopは表示しない。
")

(add-help 'max-nice-length
"許可する連鎖の最大長さ。[nil]は無制限。

(max-nice-length nil) とすると連鎖数の上限なくNice Loopを探索する。
")

(add-help 'novice-level
"ナンプレ初心者向きの設定。
localization=不使用、n-grid=不使用、tuples=不使用、配置確定法=不使用。
刈り込みが不十分だと解が得られない場合がある。「(novice-level t)」と
設定変更してから再度「(teach sample-board-6)」などとする。
")

(add-help 'middle-level
"ナンプレ初級から中級者向きの設定。
localization=使用, n-grid=不使用, tuples=2国同盟まで使用, 配置確定法=不使用。
")

(add-help 'senior-level
"ナンプレ中級から上級者向きの設定。
localization=使用, n-grid=2x2(x-wing)まで使用, tuples=3国同盟まで使用, 配置確定法=不使用。
")

(add-help 'advanced-level
"ナンプレ上級者向きの設定。
localization=使用, n-grid=3x3(swordfish)まで使用, tuples=3国同盟まで使用, 配置確定法=使用,
ALS=使用, Nice Loop=連鎖セル数5までで使用。
")

(add-help 'machine-level
"ナンプレ超上級者向きの設定。
localization=使用, n-grid=上限なしで使用, tuples=上限なしで使用, 配置確定法=使用,ALS=使用,
Nice Loop=上限なしで使用。Advanced Coloring=使用。GB-ALS=使用。cheat=許可。複数解=探索せず。
")

;;;
;;; プログラム内部で使うグローバル変数を管理する関数群
;;;
(defun answer (&optional (val nil switch))
  (cond
    ((null switch) *answer*)
    (t (setf *answer* val))))

(defun exec-count (&optional (counter nil))
  (cond
    ((null counter) *exec-count*)
    ((integerp counter) (setf *exec-count* counter))
    (t nil)))

(defun depth (&optional (level nil switch))
  (cond
    ((and (null level) switch)
     (setf *depth* 0)
     (setf *max-depth* 0))
    ((null level)
     *depth*)
    ((integerp level)
     (if (> level *max-depth*) (setf *max-depth* level))
     (setf *depth* level))
    (t nil)))

(defun applied-logics (&optional (counter nil))
  (cond
    ((null counter) *applied-logics*)
    ((integerp counter) (setf *applied-logics* counter))
    (t nil)))

(defun evil-boards (&optional (board nil sw))
"すべての手筋で手を進められなかった盤面を記録・表示する。"
  (cond
    ((null sw) ;; [*evil-boards*]の重複を除いて表示する。
     (cond
       ((null *evil-boards*) nil)
       ((listp *evil-boards*)
        (uniq-boards *evil-boards*))
       (t *evil-boards*)))
    ((null board)
     (setf *evil-boards* nil))
    ((board-p board)
     (push board *evil-boards*))
    (t (do-nothing))))

(defun uniq-boards (brd-list)
"ボードのリスト[brd-list]内の重複を除いたリストを返す。"
  (let (tmp result)
    (setf result nil)
    (cond
      ((listp brd-list)
       (setf tmp (copy-seq brd-list))
       (push (pop tmp) result)
       (dolist (i tmp) 
         (when (not (subsetp (list i) result :test #'equal-board-p))
           (push i result)))
       (identity (reverse result)))
      (t brd-list)) ))

(defun nice-count (&optional (counter nil))
  (cond
    ((null counter) *nice-count*)
    ((integerp counter) (setf *nice-count* counter))
    (t nil)))

(defun nice-loop-count (&optional (counter nil))
  (cond
    ((null counter) *nice-loop-count*)
    ((integerp counter) (setf *nice-loop-count* counter))
    (t nil)))

(defun nice-depth (&optional (level nil switch))
  (cond
    ((and (null level) switch)
     (setf *nice-depth* 0)
     (setf *max-nice-depth* 0))
    ((null level)
     *nice-depth*)
    ((integerp level)
     (if (> level *max-nice-depth*) (setf *max-nice-depth* level))
     (setf *nice-depth* level))
    (t nil)))

(defun parity-color (&optional (color nil sw))
"引数がないかnilの場合は、Advanced Coloringで使用する現在のパリティ・カラーを返す。
引数に正しいカラーを指定した場合は、現在のパリティ・カラーを指定したカラーに設定する。"
  (let (i)
    (if (null *parity-color-counter*) (setf *parity-color-counter* 0))
    (cond
      ((or (null sw) (null color))
       (nth *parity-color-counter* *parity-colors*))
      ((member color *parity-colors* :test 'equal)
       (setf i (mod (position color *parity-colors* :test 'equal) (length *parity-colors*)))
       (setf *parity-color-counter* i))
      (t nil))
    (return-from parity-color (nth *parity-color-counter* *parity-colors*))) )

(defun exchange-parity-color ()
"現在のパリティ・カラーを「反対のカラー」に切り替える。
切り替え後のパリティ・カラーを返す。"
  ;;(if (null *parity-color-counter*) (setf *parity-color-counter* 1))
  (setf *parity-color-counter* (mod (incf *parity-color-counter*) (length *parity-colors*)))
  (parity-color))

(defun opposite-color (color)
"引数で指定したカラーの「反対のカラー」を返す。"
  (cond
    ((member color *parity-colors* :test 'equal)
     (first (set-difference *parity-colors* (list color))))
    ((equal color *conflict-color*)
     *conflict-color*)))

(defun print-with-symbol-letter (&optional (switch t sw))
"[nil]以外を与えるとNice Loop経路を表示する際にラベル記号も表示する。

[t]   ==> 不連続Nice Loop  [(A)r5c7]=3=[(B)r5c3]=7=[(C)r5c2]-7-[(A)r5c7]
[nil] ==> 不連続Nice Loop  [r5c7]=3=[r5c3]=7=[r5c2]-7-[r5c7]"
  (cond
    ((null sw) *print-with-symbol-letter*)
    (t (setf *print-with-symbol-letter* switch))))

(defun letter-labels (&optional (counter 0 sw))
  "呼び出すたびにリスト[*letter-labels*]の要素を先頭(=[0]番目)から順に返す。
[*letter-labels*]は\"A\"...\"Z\",\"a\"...\"z\"と定義してある。
リスト末尾まで到達すると再び先頭の要素から順に返す。
[(print-with-symbol-letter)]が[nil]なら空文字を返す。"
  (if (and
       (identity sw)
       (zero-or-positive-integerp counter)
       )
      (letter-label-counter counter)
      ) ;; end inf
  (if (print-with-symbol-letter)
      (format nil "(~a)" (nth (letter-label-counter) *letter-labels*))
      (identity *empty-char*)
      ) ;; end if
  ) ;; end letter-labels

(defun letter-label-counter (&optional (num 0 sw))
  (let (result)
    ;;(if (null *letter-label-counter*) (setf *letter-label-counter* 0))
    (cond
      ((null sw)
       (setf result *letter-label-counter*)
       (setf *letter-label-counter* (mod (incf *letter-label-counter*) (length *letter-labels*)))
       (identity result))
      ((and (integerp num) (>= num 0) (> (length *letter-labels*) num))
       (setf *letter-label-counter* num))
      (t (error "can't happen at letter-label-counter.")))))

(defun capital-address (&optional (switch nil sw))
"セルアドレスを大文字で表示するか小文字で表示するかを設定する。
引数が[nil]なら小文字(ex.[r2c3]), [nil]以外なら大文字(ex.[R2C3])で表示する。
引数がなければ現在の設定を返す。"
  (cond
    ((null sw) *capital-address*)
    (t (setf *capital-address* switch))))

(defun max-depth () *max-depth*)

(defun max-nice-depth () *max-nice-depth*)

(defun board-print-counter (&optional (num nil))
"盤面を出力した回数を記録する。"
  (cond
    ((null num) *board-print-counter*)
    ((and (integerp num) (>= num 0)) (setf *board-print-counter* num))
    (t nil)))

(defun method-count (&optional (counter nil))
"手筋を適用した回数を記録する。"
  (cond
    ((null counter) *method-count*)
    ((integerp counter) (setf *method-count* counter))
    (t nil)))

(defun total-score (&optional (score nil switch))
"引数[score]で指定された値を[*score*]に加算する。
引数に[nil]が指定されると[*score*]を[0]にリセットする。"
  (cond
    ((null switch)
     *score*)
    ((integerp score)
     (setf *score* score))
    (t nil)))

(defun max-score (&optional (n 0 switch))
"引数[n]を難易度指数の最大値として記録する。"
  (cond
    ((null switch) *max-score*)
    ((integerp n)
     (setf *max-score* n))
    (t (do-nothing))))

(defun linkmap-counter (&optional (num nil))
"GraphViz用データのファイル名末尾に付加する系列番号を管理する。"
  (cond
    ((null num) (incf *linkmap-counter*))
    ((integerp num) (setf *linkmap-counter* num))
    (t nil)))

(defun max-weight ()
"セル間の「重み」の最大値を定義する。"
  (+ *board-size* *board-size*))

(defun method-applied (&optional (method nil switch))
"各手筋内部で手筋を適用できたときに[nil]でない値(現在は各関数名)をセットする。"
  (cond
    ((null switch) *method-applied*)
    (t (setf *method-applied* method))))

(defun print-vertices (graph)
"グラフ[graph]の頂点情報を出力する。"
  (let (cell)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf cell (cell-addr (list i j)))
        (cond
          ((typep (aref graph i j) 'vertex)
           (format t "~aはグラフの頂点です。~%" cell)
           (format t " fringe-weightは~d。~%" (vertex-fringe-weight (aref graph i j)))
           (format t " fringe-parentは~a。~%" (vertex-parent (aref graph i j)))
           (format t " fringe-statusは~s。~%" (vertex-status (aref graph i j)))
           (format t " adj-listは~s。~%" (vertex-adj-list (aref graph i j))))
          (t (format t "~aはグラフの頂点ではありません。~%" cell)))))
    (return-from print-vertices t)))

(defun print-nice-info (graph)
  (let (cell)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf cell (cell-addr (list i j)))
        (cond
          ((typep (aref graph i j) 'vertex)
           (format t "~aはグラフの頂点です。~%" cell)
           (format t " parent=~a。~%" (cell-addr (vertex-parent (aref graph i j))))
           (format t " status=~s。~%" (vertex-status (aref graph i j)))
           (format t " bivalue=~s。~%" (vertex-bivalue-cell (aref graph i j)))
           (format t " adj-list=~a。~%" (adj-list-cell-addr (vertex-adj-list (aref graph i j)))))
          (t (format t "~aはグラフの頂点ではありません。~%" cell)))))
    (return-from print-nice-info t)))

(defun print-adj-info (graph)
  (let (cell)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (setf cell (cell-addr (list i j)))
        (when (typep (aref graph i j) 'vertex)
          (format t "~aはグラフの頂点です。~%" cell)
          (format t " parent= ~a。~%" (cell-addr (vertex-parent (aref graph i j))))
          (format t " bivalue= ~s。~%" (vertex-bivalue-cell (aref graph i j)))
          (format t " adj-list= ~s~%" (vertex-adj-list (aref graph i j))))))
    (return-from print-adj-info t)))

(defun cleanup-graph (graph)
"グラフ[graph]の内容を完全に初期化する。"
  (dotimes (i *board-size*)
    (dotimes (j *board-size*)
      (setf (aref graph i j) nil)))
  (return-from cleanup-graph graph))

(defun cleanup-graph-status (graph)
"グラフ[graph]の[status]欄だけを初期化する。"
  (dotimes (i *board-size*)
    (dotimes (j *board-size*)
      (if (typep (aref graph i j) 'vertex) (setf (vertex-status (aref graph i j)) 'unseen))))
  (return-from cleanup-graph-status graph))

(defun cleanup-graph-parent (graph)
"グラフ[graph]の[parent]欄だけを初期化する。"
  (dotimes (i *board-size*)
    (dotimes (j *board-size*)
      (if (typep (aref graph i j) 'vertex) (setf (vertex-parent (aref graph i j)) nil))))
  (return-from cleanup-graph-parent graph))

(defun setup-graph-unseen (graph)
"グラフ[graph]の[unseen]欄を隣接リストをコピーし直すことで復元する。
[unseen]欄に位置情報が登録されている＝未訪問。"
  (dotimes (i *board-size*)
    (dotimes (j *board-size*)
      (when (typep (aref graph i j) 'vertex)
        (dolist (adj (vertex-adj-list (aref graph i j)))
          (push (get-vertex adj) (vertex-unseen (aref graph i j))))
        (setf (vertex-unseen (aref graph i j)) (reverse (vertex-unseen (aref graph i j)))) )))
  (return-from setup-graph-unseen graph))

(defun unseen-exist-p (graph cell)
"セル[cell]から訪れていない隣接セルがあるかないかだけを返す。
あれば[t],なければ[nil]を返す。"
  (cond
    ((null cell) nil)
    ((typep (aref graph (first cell) (second cell)) 'vertex)
     (vertex-unseen (aref graph (first cell) (second cell))))
    (t nil)))

(defun pop-unseen-cell (graph cell-0)
"セル[cell-0]の[unseen]スロットから未訪問の隣接セル・アドレスをひとつ返す。
[cell-0]と[unseen-cell]間のunseen情報は双方から削除される。"
  (let (unseen-cell)
    (setf unseen-cell (get-unseen-cell graph cell-0))
    (cond

      ((clear-unseen-info graph cell-0 unseen-cell)
       (identity unseen-cell))
      (t nil))))

(defun get-unseen-cell (graph cell-0)
"セル[cell-0]の[unseen]スロットから未訪問の隣接セル・アドレスをひとつ返す。"
  (let (unseen-0)
    (cond
      ((null cell-0) nil)
      ((typep (aref graph (first cell-0) (second cell-0)) 'vertex)
       (setf unseen-0 (vertex-unseen (aref graph (first cell-0) (second cell-0))))
       (cond
         ((identity unseen-0)
          (first unseen-0))
         ((null unseen-0) nil)))
      (t nil))))

(defun clear-unseen-info (graph cell-0 cell-1)
"セル[cell-0]とセル[cell-1]間のunseen情報を双方から削除する。"
  (let (unseen-0 unseen-1)
    (cond
      ((or
        (null cell-0)
        (null cell-1)) nil)
      ((and
        (typep (aref graph (first cell-0) (second cell-0)) 'vertex)
        (typep (aref graph (first cell-1) (second cell-1)) 'vertex))
       (setf unseen-0 (vertex-unseen (aref graph (first cell-0) (second cell-0))))
       (setf unseen-1 (vertex-unseen (aref graph (first cell-1) (second cell-1))))
       (setf (vertex-unseen (aref graph (first cell-0) (second cell-0)))
             (remove cell-1 unseen-0 :test #'equal))
       (setf (vertex-unseen (aref graph (first cell-1) (second cell-1)))
             (remove cell-0 unseen-1 :test #'equal))
       (identity graph))
      (t nil))))

(defun clear-all-unseen-info (graph cell-0)
"セル[cell-0]の[unseen]スロットの内容をすべて消去する([nil]にする)。"
  (cond
    ((null cell-0) nil)
    ((typep (aref graph (first cell-0) (second cell-0)) 'vertex)
     (setf (vertex-unseen (aref graph (first cell-0) (second cell-0))) nil))
    (t (error "can't happen at clear-all-unseen-info."))))

(defun read-chunk (&optional (data-file (namestring (truename "sudoku.data"))))
"chunk型(81桁の整数)でファイルに記録された複数のナンプレ問題のそれぞれをboard型
データ(2次元配列)に変換し、そのリストを返す。
     (setf result (read-chunk \"./mydata.data\"))
などとする。"
  (when (not (probe-file data-file)) (return-from read-chunk nil))
  (with-open-file (stream data-file :direction :input)
    (do* ((eos (cons nil nil))
          (result nil)
          (data (read stream nil eos) (read stream nil eos)) )
         ((eq data eos) (reverse result))
      (push (chunk2board data) result))))

;;;
;;;
;;; ゲーム情報の履歴を記録・管理し各盤面を検討するための関数群
;;;
;;;
(defun examin (&optional (board-or-fname nil))
"盤面を手動で検討するためのメイン関数。
引数として文字列(=ダブルクオーテーションで囲んだ文字の列)を指定するとファイル名と解釈する。
引数としてシンボルを指定するとボード型変数と解釈する。

引数を指定しないと、まずメモリ上の登録済み盤面データから選ぶか尋ねる。
選択しなかった場合は、次に盤面データが(1個以上収められた)ファイル名か、ボード型変数の入力を求める。

ファイル内の盤面データは2次元配列形式の[board型]と整数文字列の[chunk型]の両方を許している。
それぞれは名前付きでも名前無し(設定に従って自動的に命名する)でも良い。[game-node型]データも許す。

\"quit\" または \"q\" を入力すると関数[examin]の実行を中止して[nil]を返す。
"
  (let (brd user-input)

    (when (null board-or-fname)

      (when (and ;; 2024-05-01
	     (identity *sudoku-game-list*)
	     (query-y-or-n-p "メモリ上の登録済みの盤面データから選びますか。")
	     )
	(setq brd (select-game-from-memory)) ;; [select-game-from-memory] returns node.
	(when (identity brd)
	  (step-around (prepare-step-around brd))
	  (return-from examin t)
	  ) ;; end when
	)   ;; end when

      (block examin-input-loop
	(loop
          (format t "問題が格納されたシンボル名、あるいはファイル名を入力して下さい。~%")
	  (format t "[return]のみを入力すると盤面データの入力となります(\"quit\"で実行中止)。~%")
          (finish-output)
          (format t "Enter : ")
          (finish-output)
          (setf user-input (read-multiple-symbol)) ;; 仮定：OSのファイル・システムは大文字と小文字を区別する。
	  (clear-input)

	  (cond
	    ((and
	      (symbolp user-input)
	      (member user-input '(quit q exit bye) :test #'equal)
	      )
	     (return-from examin nil)
	     )
	    ((null user-input) ;; 入力が改行のみ。
             (setf brd (enter-board)) ;; 関数[enter-board]は盤面データの手動入力用関数。
	     (if (null brd)
		 (return-from examin nil)
		 )
             (finish-output)
	     (clear-input)
             (format t "入力した盤面データは\[Co\)llection\]コマンドでファイルに保存できます。~%")
             (finish-output)
	     )
            ((and ;; 入力文字列に一致するファイルが存在する。
	      (stringp user-input)
	      (probe-file user-input)
	      )
	     (setq brd (select-game-from-file user-input)) ;; ファイル内に保存されている問題から選ぶ。
	     (return) ;; exit this loop.
	     )
	    ((probe-file (first (original-read-string-list)))
	     (setq brd (select-game-from-file (first (original-read-string-list))))
	     (return) ;; exit this loop.
	     )
	    ((or ;; 入力された文字列に一致するファイルは存在しない。
	      (and
	       (stringp user-input)
	       (not (probe-file user-input))
	       )
	      (not (probe-file (first (original-read-string-list))))
	      )
	     (loop
               (format t "ファイル ~a は存在しませんでした。正しいファイル名を入力して下さい。~%"
		       (first (original-read-string-list)))
               (format t "[Return]のみを入力すると処理を終了します。~%") ;; "quit" というファイル名もあり得る。
               (finish-output)
               (clear-input)
               (format t "Enter : ")
               (finish-output)
               (setq user-input (read-multiple-symbol))
               (clear-input)
               (if (null user-input)
		   (return-from examin nil))
	       (cond
		 ((probe-file user-input) ;; ダブルクオーテーション(")で囲んだ文字列で入力した場合。
		  (setq brd (select-game-from-file user-input))
		  (return-from examin-input-loop t)
		  )
		 ((probe-file (first (original-read-string-list))) ;; ダブルクオーテーション(")なしで入力した。
		  (setq brd (select-game-from-file (first (original-read-string-list))))
		  (return-from examin-input-loop t)
		  )
		 ) ;; end cond
               )   ;; end loop
	     )
	    ((and
	      (symbolp user-input)
	      (board-p (eval user-input))
	      )
	     (setq brd (pm (eval user-input)))
	     (return) ;; exit this loop.
	     )
	    (t
	     (format t "\(~a\)というファイルは存在しません。シンボルとしても未定義です。~%" user-input)
	     )
	    )
          ) ;; end loop
	) ;; end block examin-input-loop
      )	  ;; (when (null board-or-fname)

    ;; 関数[examin]が引数なしで呼び出された場合は[user-input]には必ずボード型変数か、存在するファイル名が
    ;; 設定されている。引数ありで呼び出された場合、まだ引数の正当性は不明。
    (when (identity board-or-fname)
      (cond
	((board-p board-or-fname)
	 (setq brd (pm (new-board board-or-fname))) ;; pencil mark形式に整えておく
	 )
	((and ;; [board-or-fname]はボード型データが収められたファイル名。
	  (stringp board-or-fname)
	  (probe-file board-or-fname)
	  )
	 (setq brd (select-game-from-file board-or-fname))
	 )
	((and ;; [board-or-fname]は文字列だったが一致するファイル名は存在しなかった。
	  (stringp board-or-fname)
	  (not (probe-file board-or-fname))
	  )
	 (loop
           (format t "ファイル ~a は存在しませんでした。正しいファイル名を入力して下さい。~%" board-or-fname)
           (format t "[Return]のみを入力すると処理を終了します。~%") ;; "quit" というファイル名もあり得る。
           (finish-output)
           (clear-input)
           (format t "Enter : ")
           (finish-output)
           (setq board-or-fname (read-multiple-symbol))
           (clear-input)
           (if (null board-or-fname) ;; 入力が[return]のみなら終了。
	       (return-from examin nil))
	   (cond
	     ((and ;; ダブルクオーテーション(")で囲んだ文字列で入力した場合。
	       (stringp board-or-fname)
	       (probe-file board-or-fname)
	       )
	      (setq brd (select-game-from-file board-or-fname))
	      (return) ;; exit this loop.
	      )
	     ((and ;; ダブルクオーテーション(")なしで入力した場合。
	       (symbolp board-or-fname)
	       (probe-file (first (original-read-string-list)))
	       )
	      (setq brd (select-game-from-file (first (original-read-string-list))))
	      (return)
	      )
	     ) ;; end cond
           )   ;; end loop
	 (when (null brd)
	   (format t "指定されたファイル ~a にはナンプレの問題が存在しませんでした。~%" board-or-fname)
	   (return-from examin nil)
	   )
	 ) ;; end (stringp board-or-fname)
	(t
	 (format t "引数はボード型データを持つシンボルでもナンプレ問題を保存したファイルでもありませんでした。~%")
	 (return-from examin nil)
	 )
	) ;; end cond
      ) ;; end when

    (step-around (prepare-step-around brd))
    (return-from examin t)
    ) ;; end let
  ) ;; end examin

(defun prepare-step-around (brd)
"いくつかの初期設定を行いルート・ノードを作成して返す。"
  (let (node)
    ;;以下の設定は[NumberPlace-init.lisp]に記述することをお薦め。
    ;;(print-mini t)            ;; デフォルト盤面サイズ。[nil]=候補数字あり、[nil以外]=候補数字なしの小さな盤面。
    ;;(pause nil)               ;; 設定画面数出力ごとの一時停止は行わない。関数[examin]内のメニューで変更可能。
    ;;(allow-explore nil)       ;; [nil]なら E)xploreメニューを表示しない。
    (reset-label-list)
    (dribble-p nil)
    (setf node (create-root-node brd))
    (format t "初期盤面です。\#~d(~a)~%" (game-node-node-number node) (game-node-node-label node))
    (print-board (pm brd))
    (finish-output)

    (return-from prepare-step-around node)
    ) ;; end let
  )

(defun create-root-node (brd)
"ルートノードを作成して返す。ノード番号は0（ゼロ）"
  (let (node)
    (setf *game-node-number* 0)
    (setf node (make-game-node
                :node-number 0
                :node-label "root"
                :parent-node-number nil
                :next-node nil
                ;;:prev-board nil ;; Ver.6.8.7よりメモリ節約のため廃止した。
                :prev-methods nil
                :present-board (new-board (pm brd))
                :state 'start
                :seen nil
                :dead-route nil
		:quiz-info nil
		:quiz-list nil
		:quiz-list-backup nil
		:grouped-quiz-info nil ;; do-fundamentalなど一部の関数のみで使用する。
		:grouped-quiz-list nil ;; 同上。作成する関数は[create-genration]内を参照。
		:grouped-quiz-list-backup nil ;; 同上。
                )
          )
    (setf *root-node* node)
    (reset-game-node-list)
    (add-game-node-list node)
    (setf *game-label-list* (list '("root" 0)))
    (return-from create-root-node node))
  )

(defun create-child-node (node &optional lbl)
"渡されたノードに子ノードをひとつ作成して返す"
  (let (node-1 n)
    (setf n (game-node-node-number node))
    (setf node-1 (make-game-node
                  :parent-node-number n
                  :parent-node-label (game-node-node-label node)
                  :node-number (incf *game-node-number*) 
                  :node-label lbl
                  :next-node nil
                  ;;:prev-board nil ;; Ver.6.8.7よりメモリ節約のため廃止した。
                  :prev-methods nil
                  :present-board nil
                  :state nil
                  :seen nil
                  :dead-route nil
		  :quiz-info nil
		  :quiz-list nil
		  :quiz-list-backup nil
		  :grouped-quiz-info nil ;; do-fundamentalなど一部の関数のみで使用する。
		  :grouped-quiz-list nil ;; 同上。
		  :grouped-quiz-list-backup nil ;; 同上。
                  ))
    (add-game-node-list node-1) ;; ノードを生成された順序でリストに追加している。
    (cond
      ((null (game-node-next-node node))
       (setf (game-node-next-node node) (list node-1)))
      (t (setf (game-node-next-node node) (append (list node-1) (game-node-next-node node)))))
    (return-from create-child-node node-1)
    )
  )

(defun game-node-list ()
"ノード番号からノードを探す際に木構造探索ではなく線形探索で済むように[*game-node-list*]を使う。"
  *game-node-list*)

(defun reset-game-node-list ()
  (setf *game-node-list* nil))

(defun add-game-node-list (node)
  (cond
    ((null node) nil)
    ((typep node 'game-node)
     (push node *game-node-list*))
    (t nil))
  )

(defun find-node (p)
"指定されたノード番号[p]または、ノードラベル[p]を持つノードを返す。
     指定されたノードが存在すれば、そのノードを返す。
     指定されたノードが存在しなければ[nil]を返す。
     番号(数値)またはラベル以外を与えた場合は[nil]を返す。
Ver 2.0 2023-12-20. Fast but more memory, and uses global variable. Order(n)."
  (cond
    ((zero-or-positive-integerp p)
     (find-node-number p))
    ((stringp p)
     (find-node-label p)) )
  )

(defun find-node-number (p)
  (let (len n)
    (setf len (game-node-number)) ;; 2024-03-02
    (if (> p len) (return-from find-node-number nil))
    (setf n (- len p))
    (return-from find-node-number (nth n (game-node-list)))
    ) ;; end let
  )

(defun find-node-label (str)
  (let (lst)
    (setf lst (member str *game-label-list* :key #'car :test #'string=))
    (cond
      ((null lst) nil)
      (t (find-node-number (second (first lst)))))
    )
  )

(defun parent-node (node)
"引数で指定されたノードの親ノードを返す。"
  (let (p)
    (if (root-node-p node) nil)
    (setf p (find-node (game-node-parent-node-number node)))
    (return-from parent-node p)
    )
  )

(defun parent-board (node)
"親ノードに保存されている盤面を返す。"
  (let (p)
    (setf p (parent-node node))
    (cond
      ((null p) nil)
      (t (game-node-present-board p)))
    )
  )

(defun find-node-for-debug (p &optional (node (root-node)))
"Ver 1.0 tree walk version. O(n^2)
     ルート・ノード以外の任意のノードを引数に指定できる。デバッグ用。"
  (cond
    ((null node) nil)
    ((not (typep node 'game-node))
     nil)
    (t
     (find-node-sub-for-debug p node)))
  )

(defun find-node-sub-for-debug (p node)
  (let (result)
    (cond
      ((null node) nil)
      ((not (typep node 'game-node)) nil)
      ((null (game-node-node-number node)) nil)
      ((and (stringp p)
            (string= (game-node-node-label node) p)) ;;ラベルの大文字･小文字は区別する
       node)
      ((not (integerp p)) nil)
      ((minusp p) nil)
      ((= (game-node-node-number node) p)
        node)
      (t
       (setf result nil)
       (dolist (s (game-node-next-node node))
         (setf result (find-node-sub-for-debug p s))
         (when result
           (return-from find-node-sub-for-debug result)))) )
    )
  )

(defun root-node (&optional (node *root-node*))
  (cond
    ((and
      (not (null node))
      (typep node 'game-node))
     (setf *root-node* node))
    (t node)))

(defun game-node-number (&optional (counter -1 sw))
  (cond
    ((null sw)
     *game-node-number*)
    ((integerp counter)
     (setf *game-node-number* counter))
    )
  )

(defun game-label-list ()
  *game-label-list*)

(defun reset-label-list ()
  (setf *game-label-list* (list '("root" 0)))
  )

(defun sorted-label-list ()
  (setf *game-label-list* (sort (copy-seq *game-label-list*) #'< :key #'second))
  (return-from sorted-label-list *game-label-list*)
  )

(defun allow-explore (&optional (allow-or-not nil sw))
"隠しコマンドのメニュー表示と実行を許可するか設定する。"
  (cond
    ((null sw) *allow-explore*)
    ((null allow-or-not)
     (setf *allow-explore* nil))
    ((not (null allow-or-not))
     (setf *allow-explore* t)) )
  )

(defun long-explanation (&optional (allow-long-explanation t sw))
"関数[examin]のメニュー内で[Load]コマンドの詳しい説明を表示するか制御する。
引数なしなら現在の設定を返す。"
  (cond
    ((null sw)
     *long-explanation*)
    ((null allow-long-explanation)
     (setf *long-explanation* nil))
    (t (setf *long-explanation* t)))
  (return-from long-explanation *long-explanation*)
  )

(defun normal-explanation (&optional (allow-normal-explanation t sw))
"関数[examin]のメニュー内で通常表示のメニュー・コマンドなら[t]を返す。"
  (cond
    ((null sw)
     *normal-explanation*)
    ((null allow-normal-explanation)
     (setf *normal-explanation* nil))
    (t (setf *normal-explanation* t)))
  (return-from normal-explanation *normal-explanation*)
  )

(defun minimum-explanation (&optional (allow-minimum-explanation t sw))
"関数[examin]のメニュー内で必要最小限のメニュー・コマンドとして表示するかを返す。"
  (cond
    ((null sw)
     *minimum-explanation*)
    ((null allow-minimum-explanation)
     (setf *minimum-explanation* nil))
    (t (setf *minimum-explanation* t)))
  (return-from minimum-explanation *minimum-explanation*)
  )

(defun no-explanation (&optional (allow-no-explanation t sw))
"関数[examin]のメニューのメニューを表示するかを返す。"
  (cond
    ((null sw)
     *no-explanation*)
    ((null allow-no-explanation)
     (setf *no-explanation* nil))
    (t (setf *no-explanation* t)))
  (return-from no-explanation *no-explanation*)
  )

(defun no-message-print ()
  (long-explanation nil)
  (normal-explanation nil)
  (minimum-explanation nil)
  (ignore-show-help t)
  )

(defun minimum-message-print ()
  (long-explanation nil)
  (normal-explanation nil)
  (minimum-explanation t)
  )

(defun normal-message-print ()
  (long-explanation nil)
  (normal-explanation t)
  (minimum-explanation t)
  )

(defun long-message-print ()
  (long-explanation t)
  (normal-explanation t)
  (minimum-explanation t)
  )

(defun examin-message-level ()
"現在のメッセージ表示量のレベルを \"Command-mode\" \"Minimum\" \"Normal\" \"Verbose\" で返す。"
  (cond
    ((and
      (null (long-explanation))
      (null (normal-explanation))
      (minimum-explanation))
     "Minimum") ;; minimum
    ((and
      (null (long-explanation))
      (normal-explanation)
      (minimum-explanation))
     "Normal") ;; normal
    ((and
      (long-explanation)
      (normal-explanation)
      (minimum-explanation))
     "Verbose") ;; verbose
    ((ignore-show-help)
     "Command-mode") ;; command mode = no message.
    )
  )

(defun can-dribble ()
"実行する処理系が大域変数[*can-dribble*]に登録された[dribble]関数使用可能な処理系かどうかを返す。"
  (member (string-upcase (lisp-implementation-type)) *can-dribble* :test #'string=)
  )

(defun dribble-p (&optional (dribbling nil sw))
"処理系依存機能[dribble]関数の使用を許可するかどうかを設定します。
[can-dribble]関数に処理系名が登録されている場合のみ有効です。"
  (cond
    ((null sw)
     *dribbling*)
    ((null dribbling)
     (setf *dribbling* nil))
    ((not (null dribbling))
     (setf *dribbling* t))
    )
  (return-from dribble-p *dribbling*)
  )

(defun find-all-logical-path (board-or-node &optional (min 0))
"理詰めで解に到達できる全ての手筋の組み合わせを調べる。
問題によっては数十万通り以上の盤面検査が必要となり数時間から数日を要する場合がある。
オプショナル引数[min]は非負整数。分単位で実行を中断してその後の処理を選択できる。
[min]がゼロの場合は中断なし。

(print-way-to-goal (find-all-logical-path [board])) で全ての解法手順図を表示する。"
  (let (brd node fmt start-time elapsed-time time-limit)

    (cond
      ((board-p board-or-node)
       (setf brd (pm board-or-node)) ; 盤面を刈り込んでペンシルマーク形式にする
       (setf node (create-root-node brd)) )
      ((typep board-or-node 'game-node)
       (setf node board-or-node))
      (t (error "find-all-logical-path~%")))

    (setf start-time (get-universal-time))
    (if (or (not (integerp min)) (<= min 0)) (setf min 0))
    (setf time-limit (* min 60))
    (setf fmt (format nil "~~~d,8T" 16))


    ;; [elapsed-time] and [start-time] are gloval for
    ;; this locals function[find-all-logical-path-sub].
    (labels
        (
         (find-all-logical-path-sub (node)      ;; Local function 1/1
           (let (ch minutes)

             (setf node (create-generation node))
             ;;(format t "find-all-logical-path-sub: node=~s~%" node)

             (dolist (child-node (game-node-next-node node))
               (when (equal (game-node-state child-node) 'applied) ;; 盤面に変化がある=手が進んだ
                 (find-all-logical-path-sub child-node)) ;; 手筋適用を続ける

               (setf elapsed-time (- (get-universal-time) start-time))
               (cond
                 ((and ;; 一定時間ごとの自動停止=オフ、自動保存=オン。
                   (numberp min)
                   (zerop min)
                   (plusp (auto-save-minutes)))
                  (when (>= elapsed-time (* (auto-save-minutes) 60)) ;; time in seconds.
                    (format t "Auto saving\(~a\)...~%" (iso8601-date-string 'long 'time-only))
                    (finish-output)
                    (save-node-data (root-node)) ;; デフォルトのファイル名で保存。
                    (setf start-time (get-universal-time))))
                 ((and ;; 一定時間ごとの自動停止=オフ、自動保存=オフ。
                   (numberp min)
                   (zerop min)
                   (zerop (auto-save-minutes)))
                  (format t "一定時間ごとの一時停止も一定時間ごとの自動保存も設定されていません。~%")
                  (finish-output)
                  (clear-input)
                  (when (not (query-yes-or-no-p "本当にこのままで宜しいですか？"))
                    ;;(finish-output)
                    ;;(clear-input)
                    (loop
                     (block select-loop
                       (format t "~8,8tA=一定時間ごとに一時停止して以後の進行を選択する。~%")
                       (format t "~8,8tB=一時停止せず、一定時間ごとにファイルに自動保存する。~%")
                       (format t "どちらを選びますか？ ")
                       (finish-output)
                       (setf ch (read-char))
                       (clear-input)
                       (case ch
                         ((#\A #\a)
                          (format t "一時停止するまでの時間(分単位)を入力して下さい。")
                          (finish-output)
                          (setf min (read))
                          (clear-input)
                          (when (and (numberp min) (plusp min))
                            (find-all-logical-path (root-node) min)
                            (return-from find-all-logical-path node))
                          )
                         ((#\B #\b)
                          (format t "一定時間ごとにファイルに自動保存する時間(分単位)を入力して下さい。")
                          (finish-output)
                          (setf minutes (read))
                          (clear-input)
                          (when (and (numberp minutes) (plusp minutes))
                            (auto-save-minutes minutes)
                            (find-all-logical-path (root-node) 0)
                            (return-from find-all-logical-path node))
                          )
                         (otherwise
                          (return-from select-loop nil) ;; goto next loop
                          )
                         ) ;; end case
                       )   ;; end catch
                     )     ;; end loop
                    )      ;; end when
                  )
                 ((and ;; 一定時間ごとの自動停止=オン、自動保存=オフ。
                   (numberp min)
                   (plusp min)
                   (zerop (auto-save-minutes)))
                  (when (>= elapsed-time time-limit)
                    (format t "~d分経過しました。~%" min)
                    (format t (concatenate 'string " N)ext" fmt
                                           "探索が終了するか再び~d分経過するまで探索を続けます。~%") min)
                    (format t (concatenate 'string " C)hange" fmt
                                           "時間を変更して探索を続けます。~%"))
                    (format t (concatenate 'string " I)nterrupt" fmt
                                           "探索を打ち切って終了します。~%"))
                    (format t "*Select menu : ")
                    (finish-output)
                    (setf ch (read-char))
                    (clear-input) ;;2文字目の#\newlineを消去。
                    (case ch
                      ((#\N #\n #\Newline)
                       (format t "終了するか~d分経過するまで探索を続けます。~%" min)
                       (setf time-limit (* min 60))
                       (format t "Saving...~%")
                       (save-node-data (root-node))
                       (setf start-time (get-universal-time))
                       )
                      ((#\C #\c)
                       (format t "探索を一時停止するまでの時間を変更します。~%")
                       (format t "現在の一時停止までの時間は~d分です。何分に変更しますか？ " min)
                       (finish-output)
                       (setf min (read))
                       (clear-input)
                       (setf time-limit (* min 60))
                       (format t "Saving...~%")
                       (save-node-data (root-node))
                       (setf start-time (get-universal-time))
                       )
                      ((#\I #\i)
                       (format t "探索を打ち切って終了します。~%")
                       (return-from find-all-logical-path nil)
                       )
                      (otherwise (format t "終了するか~d分経過するまで探索を続けます。~%" min)
                                 (format t "Saving...~%")
                                 (finish-output)
                                 (save-node-data (root-node))
                                 (setf start-time (get-universal-time))
                                 )
                      ) ;; end case
                    )
                  )
                 ((and ;; 一定時間ごとの自動停止=オン、自動保存=オン。    
                   (numberp min)
                   (plusp min)
                   (plusp (auto-save-minutes)))
                  (setf minutes (auto-save-minutes)) ;; 自動停止を優先して、自動保存を停止。
                  (auto-save-minutes 0)
                  (find-all-logical-path-sub node)
                  (auto-save-minutes minutes)
                  ) ;; end and
                 )  ;; end cond
               )   ;; end dolist
             ) ;; end let
           )   ;; end definition of find-all-logical-path-sub.
	 ) ;; end definition of labels
      (find-all-logical-path-sub node)
      ) ;; end labels
    (return-from find-all-logical-path node)
    ) ;; end let
  ) ;; end find-all-logical-path

(defun create-generation (node)
"引数で与えられた現在のノードに記録されている現在の盤面に対して各手筋を適用した結果を子ノードに記録する。
既に作成済みなら何もしない。子ノードを作成して親ノードとなった現在のノードを返す。"
  (let (brd-1 brd-2 p quiz-info)

    ;; このノードが処理済みなら何もしない。
    (when (game-node-seen node)
      (return-from create-generation node) )

    (setf (game-node-seen node) t)

    ;; このノードが処理不要または処理不能なら何もしない。
    (when (member (game-node-state node) '(finished unsolved inconsistent))
      (return-from create-generation node)
      ) ;; end when

    (dolist (method (permitted-methods))
      (setf brd-1 (new-board (game-node-present-board node))) ;;現在のノードに記録されている盤面
      (multiple-value-setq (brd-2 quiz-info) (funcall method brd-1)) ;;手筋適用後の盤面 2024-01-19
      (debug-write "create-generation" (format nil "method=~a, quiz-info=~s" method quiz-info))

      (cond
        ((finished-p brd-2) ;; 解に到達
         (setf p (create-child-node node))
         (setf (game-node-state p) 'finished)
         (setf (game-node-present-board p) brd-2)
         (setf (game-node-prev-methods p) method)
         (if quiz-info (setf (game-node-quiz-info p) quiz-info))
	 (when quiz-info
	   (setf (game-node-quiz-list p) (length-list (length (flatten-quiz-info quiz-info))))
	   (setf (game-node-quiz-list-backup p) (game-node-quiz-list p))
	   (when (multi-position-function-p method) ;; 同じセルに同じ削除・確定情報が発生する関数か？
	     (setf (game-node-grouped-quiz-info p)
		   (reduce-solution-info (get-solution-info-from-quiz-info quiz-info)))
	     (setf (game-node-grouped-quiz-list p)
		   (length-list (length (game-node-grouped-quiz-info p))))
	     (setf (game-node-grouped-quiz-list-backup p) (game-node-grouped-quiz-list p))
	     ) ;; end when
	   ) ;; end when
         (setf (game-node-seen p) t)
         )
        ((inconsistent-p brd-2) ;; 盤面に矛盾がある。判定は[applied]より前である必要がある。
         (setf p (create-child-node node))
         (setf (game-node-state p) 'inconsistent)
         (setf (game-node-present-board p) brd-2)
         (setf (game-node-prev-methods p) method)
         (if quiz-info (setf (game-node-quiz-info p) quiz-info)) ;; 2024-01-19
         (setf (game-node-seen p) t)
         ;; 矛盾が発生したケースを収集する。
         (inconsistent-case (list brd-1 method (game-node-node-number p) ))
         )
        ((not (equal-board-p brd-1 brd-2)) ;; 矛盾がない&盤面に変化がある→手が進んだ[applied]
         (setf p (create-child-node node))
         (setf (game-node-state p) 'applied)
         (setf (game-node-present-board p) brd-2)
         (setf (game-node-prev-methods p) method)
         (if quiz-info (setf (game-node-quiz-info p) quiz-info)) ;; 2024-01-19
	 (when quiz-info
	   (setf (game-node-quiz-list p) (length-list (length (flatten-quiz-info quiz-info))))
	   (setf (game-node-quiz-list-backup p) (game-node-quiz-list p))
	   ;;(when (member method *multi-position-function* :test #'equal)
	   (when (multi-position-function-p method)
	     (setf (game-node-grouped-quiz-info p)
		   (reduce-solution-info (get-solution-info-from-quiz-info quiz-info)))
	     (setf (game-node-grouped-quiz-list p)
		   (length-list (length (game-node-grouped-quiz-info p))))
	     (setf (game-node-grouped-quiz-list-backup p) (game-node-grouped-quiz-list p))
	     )
	   )
         ;;(setf (game-node-seen p) t)
         )
        ((equal-board-p brd-1 brd-2) ;; 盤面に変化がない＝適用した手筋では解けなかった
         (setf p (create-child-node node))
         (setf (game-node-state p) 'unsolved)
         ;;(setf (game-node-present-board p) brd-2) ;; 2024-01-10 メモリ節約のため省略。
         (setf (game-node-prev-methods p) method)
         (if quiz-info (setf (game-node-quiz-info p) quiz-info)) ;; 2024-01-19
	 (when quiz-info
	   (setf (game-node-quiz-list p) (length-list (length (flatten-quiz-info quiz-info))))
	   (setf (game-node-quiz-list-backup p) (game-node-quiz-list p))
	   ;;(when (member method *multi-position-function* :test #'equal)
	   (when (multi-position-function-p method)
	     (setf (game-node-grouped-quiz-info p)
		   (reduce-solution-info (get-solution-info-from-quiz-info quiz-info)))
	     (setf (game-node-grouped-quiz-list p)
		   (length-list (length (game-node-grouped-quiz-list p))))
	     (setf (game-node-grouped-quiz-list-backup p) (game-node-grouped-quiz-list p))
	     )
	   )
         (setf (game-node-seen p) t)
         )
        ) ;; end cond
      )   ;; end dolist

    (when (all-child-node-unsolved-p node)
      (mark-dead-route node)
      )

    (return-from create-generation node)
    )
  )

(defun all-child-node-unsolved-p (node)
"引数で指定されたノードの子ノードの[state]がすべて(['applied]か['finished])以外なら[nil]"
  (if (null (game-node-next-node node)) (return-from all-child-node-unsolved-p nil))
  (dolist (p (game-node-next-node node))
    (if (member (game-node-state p) '(applied finished))
        (return-from all-child-node-unsolved-p nil))
    )
  (return-from all-child-node-unsolved-p t)
  )

(defun mark-dead-route (node)
"関数[all-child-node-unsolved-p]によって、引数[node]の子ノードが全て['unsolved]で
あることを確認してから呼び出すこと。
[node]の全ての子ノードのフィールド[dead-route]を[t]にセットし、
[node]から遡れる全ての親ノードのフィールド[dead-route]も[t]にセットする。"
  (let (n p)
    (setf (game-node-dead-route node) t)
    (setf (game-node-state node) 'dead-route)
    (setf n (game-node-node-number node)) ;; 現在のノード番号を取得。
    (loop
      (if (zerop n) (return-from mark-dead-route node)) ;; root nodeに到達した。
      (setf p (find-node n)) ;; 親ノードに移動。
      (setf (game-node-dead-route p) t)
      (setf n (game-node-parent-node-number p))
      )
    (return-from mark-dead-route node)
    )
  )

(defun step-around (node)
"次の処理をユーザが選択する。

以下は、実装に必要と思われる情報。

[手筋情報] ::= ([手筋名] [候補数字情報]) 
               ( ([手筋名] [候補数字情報])... ) | nil ;
[候補数字情報] ::=     ( ([候補数字適用種別] [位置情報])…) |
                     ( ([候補数字適用種別] [位置情報付き候補数字])… ) ;
[候補数字適用種別] ::= ‘delete | ‘fix ;
[位置情報] ::= ( ([行] [列])+ … ) ;
[位置情報付き候補数字] ::= ( ([行] [列]) [候補数字])+ … ) ;
[候補数字] ::= [数字] | ([数字]+ …) ;

以下のメニューはCLISPでのVerboseモード(menu→verbose)。

 I)nformation   現在の盤面と付随する情報を表示します。
 P)ause(nil)    指定した盤面数を出力するごとに一時停止します。
 T)esuji        現在の盤面に適用可能な手筋一覧を表示します。
 De)scription   指定されたルート番号の解法過程を表示します。
                カレント・ノードが指定されたルート番号のノードに変わります。
                数値を直接入力することも出来ます。
 Gu)ess         検討中の盤面を使って手筋習得練習を行います。
 Dr)ibble       画面出力を指定したファイルに保存します。
                CLISPで使用可能な処理系依存機能です。
 G)oal          解決済みの解き筋を表示します。
 Ro)ute         現時点までに判明している解き筋を表示します。
 Ex)plore       全ての解法過程ルートを探索します。一時停止設定も可。
 A)uto save(5)  解法過程の途中結果を設定分数ごとにファイルに保存します。
                Exploreコマンドでの一時停止設定が優先します。
 B)oard         候補数字ありの盤面と、なしの小さな盤面を切り替えます。
 F)ind          指定されたノード番号/ラベルを持つノードに移動します。
 Ch)ange        現在のノードのラベルを変更します。
 U)p            親ノードに移動します。
 Sa)ve          現時点までの解法経路情報を保存します。
 Lo)ad          ファイルから解法経路情報を読み込みます。
                最後に読み込んだ解法経路情報を関数[examin]のデータとして設定します。
                検討を中断した状態から再開できます。
 O)utput        現時点までの解法ルート図(テキスト)を保存します。
                解法ルート情報が存在しなければ保存用ファイルも作成されません。
 Se)lect Game   ナンプレ問題を選択します。ナンプレ問題群のリセットもここ。
 En)ter Game    ナンプレ問題を新規に手入力します。
 St)ore Games   メモリ上の全てのナンプレの問題をファイルに保存します。
 Re)ad games    ファイルからナンプレの問題を読み込みます。
                名前を指定していないナンプレ問題に半自動で名前を付けます。
 Co)llection    現在の盤面をファイルに追記します。
 Lp)r           指定するノード番号の盤面を印刷します。
 Le)vel         使用する手筋と手筋に対する制限を5段階から選びます。
 Me)nu          メニューの表示量を3段階で選びます。現在はVerboseです。
 Ev)al          設定変更用関数などを評価する。
 Q)uit          検討を終了します。
 H)elp          短い手筋解説を表示します。
 V)ersion       実行中のNumberPlace.lispのバージョンを表示します。
"
;;
  (let (entered-command brd impli-list select quiz-info-list show-help n)
    (save-env)
    (setq entered-command nil)
    (setq show-help t)
    ;;(ignore-show-help t) ;; [t]なら[show-help]が[t]でもメニューを表示しない。
    ;;基本的に NumberPlace-init.lisp 内で設定する。

    (block step-around-loop-block
      (loop ;; [quit]コマンドが入力されるまでloop内を永久に実行する。
	    (catch 'step-around-loop
              (explanation-level 0)
              (board-print-counter 0)
              (print-check nil)

	      ;; 両方が[t]でなければメニューを表示する。
              (when (and (identity show-help) (not (ignore-show-help)))
		;;
		;;            (ignore-show-help)
		;;                  |   t  |  nil |
		;;            ---------------------
		;; show-help  |  t  |  非  |  表  |
		;;            ---------------------
		;;            |  nil|  非  |  非  |
		;;            ---------------------
		;;
		(print-repeated-char-string 72 #\-)
		(format t "*現在のノードは \#~d(~a) です。~%"
			(game-node-node-number node) (game-node-node-label node))
		(print-repeated-char-string 72 #\-)
		(finish-output)
		(print-step-around-menu)
		(finish-output)
		) ;; end when

	      ;; 関数[put-bold-string]出力で、関数[step-around]の初回実行時のみプロンプト文字列が乱れる。
	      ;; 追記：[put-color-string]でも同じくプロンプト文字列が乱れる。
	      ;;
	      ;; *(CLISP/X86_64 22:4) Select menu : u : ;; 初回表示。
	      ;; *(CLISP/X86_64 22:02:47) Select menu : ;; 2回目以降の表示。正しい。 
	      ;;
	      ;; [26]> (prompt-string)
	      ;; "*(CLISP/X86_64 15:56:20) Select menu : " ;; 正常。
	      ;; [27]> (setf x (prompt-string))
	      ;; "*(CLISP/X86_64 15:56:38) Select menu : " ;; 正常。
	      ;; [28]> (put-bold-string 'black x)
	      ;; *(CLISP/X86_64 15:56:38) Select menu :    ;; 正常。
	      ;;
	      ;; (put-bold-string 'black "Select menu : ") ;; 正常。
	      ;; (put-bold-string 'black (prompt-string)) ;; 単体実行では常に正常。
	      ;;

	      ;;(set-ansi-text-color (eval (rest (assoc 'black *parity-color-list*)))) ;; 効果なし。
	      ;;(reset-all-attributes)
	      ;;(finish-output)

	      ;;
	      ;; (setq tmp (prompt-string))
	      ;; (format t "(string= ~a (put-bold-string 'blue ~a 'text-color))=~a~%"
	      ;;     tmp tmp (string= tmp (put-bold-string 'blue tmp 'text-color)))
	      ;;     ==> t
	      ;;
	      ;;#+clisp (write (prompt-string) :escape nil)
	      ;;#+sbcl  (print-colored-string 'blue (prompt-string) 'text-color)
	      ;;(put-bold-string 'blue (prompt-string))
              ;;(finish-output)

              ;; 1行に並ぶ複数のシンボルを文字列として入力する。先頭のシンボルが文字列として
	      ;; [entered-command]にセットされ、もしあれば、2番目以降のシンボルが文字列としてリスト
	      ;; [rest-string-list]にセットされる。大文字と小文字を区別する。
	      ;; 2番目以降のシンボルが入力されなければリスト[rest-string-list]は[nil]。
	      ;; 何も入力されなければ(改行のみ)ならば[entered-command]も[rest-string-list]も[nil]。
	      ;; 2番目の返り値は関数[rest-of-multiple-read-string]または関数[rest-string]
	      ;; を通してもアクセスできる。値は大域変数に保存されているので関数を通して
	      ;; アクセスする場合は2番めの返り値を受け取った変数の有効範囲外でもアクセスできる。
	      (let (org-symbol)
		(loop
		  #+clisp (write (prompt-string) :escape nil)
		  ;;#+sbcl  (print-colored-string 'blue (prompt-string) :color-pattern 'text-color)
		  #+sbcl  (print-colored-string 'blue (prompt-string) :text-or-background 'text-color)
		  ;;(put-bold-string 'blue (prompt-string))
		  (finish-output)
		  (setq org-symbol (read-multiple-symbol))
		  (when (integerp org-symbol) ;; 数字形式の文字列の場合はそのまま。
		    (setq entered-command org-symbol)
		    (return) ;; exit this loop.
		    ) ;; end when
		  ;; 入力された文字列で識別できるコマンド文字列のリストを返す。リスト長が1なら特定。
		  (setq entered-command (get-command-full-name org-symbol (step-around-menu-list)))
		  (cond
		    ((and
		      (zerop (length entered-command))
		      (null org-symbol)
		      )
		     (format t "メニュー内のいずれかのコマンドを入力して下さい。~%")
		     )
		    ((and
		      (zerop (length entered-command))
		      (identity org-symbol)
		      )
		     (format t "メニューに存在しないコマンドです(~a)。~%" org-symbol)
		     )
		    ((= (length entered-command) 1)
		     (setq entered-command (first entered-command))
		     (return)  ;; exit this loop
		     )
		    ((>= (length entered-command) 2)
		     (format t "入力した ~a だけでは、どのコマンドか特定できません~a。~%"
			  org-symbol (mapcar #'string-capitalize entered-command))
		     )
		    ) ;; end cond
		  ) ;; end loop
		) ;; end let

              (setq show-help t)

              (cond
		;;---------------------------------------------------------------------------------
		((equal entered-command 'information) ;; 現在の情報を表示する。 
		 (print-node node)
		 ;; 存在するラベルとノード番号範囲を表示する。
		 (cond
                   ((zerop (game-node-number))
                    (format t "*ノード番号はルート・ノードの ~d のみです。~%" (game-node-number)))
                   ((plusp (game-node-number))
                    (setq impli-list (get-implication-node-number (root-node)))
                    (format t "*[意味のあるノード]\/\[全ノード\] は 0..~d\/0..~d の ~d 個です。~%"
                            (car (last impli-list))
                            (game-node-number)
                            (length impli-list) ) )
                   (t (error "\(game-node-number\)が負数を返しました。~%"))
                   ) ;; end cond
		 (cond
                   ((zerop (length (game-label-list)))
                    (format t "*ラベルを持つノードはありません。~%"))
                   ((plusp (length (game-label-list)))
                    (format t "*ラベルを持つノードは ~d 個あります。~%" (length (game-label-list)))
                    (dolist (s (sorted-label-list))
                      (format t "~a (\#~d)~%" (first s) (second s))
		      ) ;; end dolist
		    )   ;; end (plusp..
                   )    ;; end 2nd cond
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'tesuji) ;; 現在の盤面に適用可能な手筋一覧を表示する。
		 (print-methods node)
		 )
		;;---------------------------------------------------------------------------------
		((or ;; 指定されたルートの手筋解法過程を表示する。
                  (integerp entered-command) ;; 数値を直接指定した場合もルート番号の指定とみなす。
                  (equal entered-command 'description)
                  )
		 (let (current-node-number dest-node-number route-number-list
                       parent-node-number route-str)
		   (block description-block
                     (cond
                       ((integerp entered-command)
			(setq dest-node-number entered-command))
		       ((and
			 (identity (rest-symbol)) ;; 先行入力があった。
			 (integerp (first (rest-symbol)))
			 )
			(setq dest-node-number (first (rest-symbol)))
			)
                       (t ;; description
			(format t "*解法過程を表示したいルート番号を入力して下さい。(\#1...\#~d) : "
				(game-node-number))
			(finish-output)
			(setq dest-node-number (read))
			(clear-input)
			)
                       )
		     (debug-write "step-around-description"
				  (format nil "dest-node-num=~s~%" dest-node-number))
		     (loop
                       (cond
			 ((not
			   (and
			    (integerp dest-node-number)
			    (<= 0 dest-node-number)
			    (<= dest-node-number (game-node-number))
			    ) ;; end and
			   )  ;; end not
			  (format t "*存在する範囲のルート番号(\#1..\#~d)を指定して下さい\(中止は\"quit\"\)。: "
				  (game-node-number))
			  (finish-output)
			  (setq dest-node-number (read))
			  (clear-input)
			  (if (and
			       (not (integerp dest-node-number))
			       (member dest-node-number '(quit q exit bye) :test #'equal)
			       )
			      (return-from description-block nil)
			      ) ;; end if
			  )
			 (t (return) )
			 ) ;; end cond
		       )   ;; end loop
                     (setq route-number-list nil)
                     ;; saves current node number.
                     (setq current-node-number (game-node-node-number node))
                     (setq n dest-node-number)
                     (loop ;; ユーザが指定した目的ノードから現ノードまで遡る。
			   ;; 完全に別ルートならルート・ノードからの解法過程。
			   (if (or (= n current-node-number) (zerop n))
			       (return)
			       ) ;; exit this loop.
			   (setq node (find-node n))
			   (setq parent-node-number (game-node-parent-node-number node))
			   (push (list parent-node-number n) route-number-list)
			   (setq n parent-node-number)
			   ) ;; end loop
                     ;;(format t "route-number-list=~s~%" route-number-list)
                     ;; route-number-list=((0 9) (9 22) (22 32))
                     (dolist (p route-number-list)
                       ;;(format t "p=~a~%" p)
                       ;; p=(0 9) ;; ノード[0]からノード[9]への経路。
                       (explanation-level 11)
                       (print-check t)
                       (setq node (find-node (second p)))
                       (setq brd (new-board (parent-board node)))
                       (cond
			 ((game-node-dead-route node)
			  (setq route-str *dead-end-shaft-string*))
			 (t
			  (setq route-str *normal-shaft-string*)))
                       (format t "==============================~%") 
                       (format t "解法ルート\[~d\] \#~d ~a\> \#~d ~a の解法手順を表示します。~%"
                               dest-node-number
                               (first p)
                               route-str
                               (second p)
                               (function-name-to-tesuji-name (game-node-prev-methods node))
                               )
                       (format t "==============================~%") 
                       (funcall (game-node-prev-methods node) brd)
                       (print-node node)
                       ) ;; end when
                     ;;(setf node (find-node current-node-number)) ;; restore node. 2024-02-29以前の動作。
		     (setq node (find-node dest-node-number)) ;; 2024-02-29 表示先のノードに移動する。
		     ) ;; end block description-block
                   )   ;; end let
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'guess)
		 (let (start-time elapsed-time game-state)
		   (format t "必要な情報を準備します...")
		   (setq start-time (get-internal-real-time))
		   (setq game-state (game-node-state node))

		   ;; bug-fix 2024-03-30
		   (when (member game-state '(finished unsolved inconsistent) :test #'equal)
		     (cond
		       ((eq game-state 'finished)
			(format t "この盤面は解に到達しているので問題作成は出来ません。~%")
			)
		       ((eq game-state 'unsolved)
			(format t "この盤面は設定された手筋群では解けないため問題作成が出来ません。~%")
			)
		       ((eq game-state 'inconsistent)
			(format t "この盤面には矛盾があるため問題作成は出来ません。~%")
			)
		       ) ;; end cond
		     (throw 'step-around-loop nil)
		     ) ;; end when

		   (setq quiz-info-list (get-quiz-info-list node))
		   (setq elapsed-time (- (get-internal-real-time) start-time))
		   (format t "準備が整いました(~,4,,f sec)。~%"
			   (float (/ elapsed-time internal-time-units-per-second)))
		   (finish-output)
		   (debug-write "guess-command" (format nil "~a~%" quiz-info-list))
		   (guess-game quiz-info-list)
		   ) ;; end let
		 )
		;;---------------------------------------------------------------------------------
		((and
                  (can-dribble)
                  (equal entered-command 'dribble) ;; 画面出力をファイルにも保存する。
		  )
		 (let (fname)
		   (dribble-p (not (dribble-p)))
		   (cond
                     ((dribble-p)
		      (cond
			((null (rest-symbol))
			 (format t "画面出力を記録するファイル名を入力して下さい。~%")
			 (format t "[ファイル名]+[-年月日時分秒].txt という形式のファイルに記録します。~%")
			 (format t "入力を省略するとファイル名部分は[dribble]となります。~%")
			 (format t "Enter file name : ")
			 (finish-output)
			 (setq fname (read-line))
			 (clear-input)
			 (if (member fname '("QUIT" "Q" "EXIT" "BYE") :test #'string=)
			     (throw 'step-around-loop nil)
			     ) ;; end if
			 )
			((identity (rest-symbol)) ;; 先行入力があった。
			 (setq fname (second (original-read-string-list)))
			 )
			) ;; end cond
                      (when (zerop (length fname))
			(setq fname '"dribble")
			)
                      (format t "画面出力のファイルへの記録を開始します。~%")
                      (finish-output)
                      (dribble (concatenate 'string fname "-"
                                            (iso8601-date-string 'short 'date-and-time) ".txt"))
                      )
                     ((null (dribble-p))
                      (dribble) ;; dribble stop.
                      (format t "画面出力のファイルへの記録を終了しました。~%")
                      (finish-output)
                      )
                     )
		   (setq show-help nil) ;; ヘルプ・メニューの再表示を省略。
		   )			;; end let
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'goal) ;; 判明している解き筋を表示する(way to goal)。
		 (print-way-to-goal (root-node) 'finished)
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'route) ;; 現時点までの解き筋の途中結果を表示する。
		 (print-way-to-goal (root-node) 'next-node-null)
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'board) ;; 候補数字ありとなしの盤面を切り替える。
		 (print-mini (not (print-mini)))
		 (print-board (pm (game-node-present-board node)))
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'find) ;; 指定したノード番号/ラベルに移動する。
		 (let (check-ok node-num-or-label)
		   (setf check-ok nil)
		   (block find-block
		     (loop
		       (cond
			 ((identity (rest-symbol)) ;; 先行入力があった。
			  (cond
			    ((integerp (first (rest-string)))
			     (setq node-num-or-label (first (rest-symbol)))
			     )
			    ((symbolp (first (rest-symbol))) ;; ラベル指定。
			     ;; 大文字・小文字区別のため保存されている入力文字列を使う。
			     (setf node-num-or-label (second (original-read-string-list)))
			     )
			    ) ;; end cond
			  )
			 ((null (rest-symbol)) ;; 先行入力がなかった。
			  (format t "*Enter node number/Label name(中止は\"quit\") : ")
			  (finish-output)
			  (setq node-num-or-label (read-line))
			  (clear-input)
			  (cond
			    ((string-digit-p node-num-or-label)
			     (setq node-num-or-label (string-to-integer node-num-or-label))
			     )
			    ((and
			      (not (integerp node-num-or-label))
			      (member node-num-or-label '(quit q exit bye) :test #'equal)
			      )
			     (return-from find-block nil)
			     )
			    ) ;; end cond 
			  )   ;; end (null (rest-symbol))
			 )    ;; end cond
		       (reset-rest-symbol)
		       (cond
			 ((zero-or-positive-integerp node-num-or-label)
			  (if (not (<= 0 node-num-or-label (game-node-number)))
			      (progn
				(format t "*存在する範囲のノード番号を指定して下さい(0..~d)~%"
					(game-node-number))
				(finish-output)
				)
			      (setq check-ok t)
			      ) ;; end if
			  )     ;; end zero-or-positive-integerp
			 ((stringp node-num-or-label)
			  (if (not (label-exist-p node-num-or-label))
			      (progn
				(format t "*ラベル ~a は存在しません。" node-num-or-label)
				(format t "Informationコマンドでラベル名を確認して下さい。~%")
				(finish-output)
				) ;; end progn
			      (setq check-ok t)
			      )		      ;; end if
			  )		      ;; end stringp
			 )		      ;; end cond
		       (if check-ok (return)) ;; exit loop.
		       )		      ;; end loop
                     (setf node (find-node node-num-or-label))
		     (print-node node)
		     ) ;; end block find-block
		   )   ;; end let
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'change) ;; 現在のノードのラベルを変更する。
		 (let (str)
		   (cond
		     ((rest-symbol)
		      (setq node (change-node-label node (second (original-read-string-list))))
		      )
		     ((null (rest-symbol))
		      (setq str (read-line))
		      (if (member (string-upcase str) '("QUIT" "Q" "EXIT" "BYE") :test #'string=)
			  (throw 'step-around-loop nil)
			  )
		      (setq node (change-node-label node str))
		      )
		     )			;; end cond
		   (setf show-help nil) ;; ヘルプ・メニューの再表示を省略。
		   )			;; end let
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'up) ;; 親ノードに移動する。
		 (cond
                   ((not (root-node-p node))
                    (setf node (parent-node node)))
                   (t
                    (format t "既にルート・ノードにいるので親ノードは存在しません。~%")))
		 ;;(setf n (game-node-parent-node-number node))
		 ;;(setf node (find-node n))
		 (print-node node))
		;;---------------------------------------------------------------------------------
		((equal entered-command 'save) ;; 解法手順情報を保存する。
		 (if (rest-string)
		     (save-node (root-node) (second (original-read-string-list))) ;; 先行入力があった。
		     (save-node (root-node) nil)
		     ) ;; end if
		 (setf show-help nil)
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'load) ;; 解法手順情報をファイルから読み込む。
		 (if (rest-string)
		     (root-node (load-node (second (original-read-string-list)))) ;; 先行入力があった。
		     (root-node (load-node)) ;; 先行入力がない。
		     ) ;; end if
		 (setf show-help nil)
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'pause) ;; 指定した盤面数を出力ごとに一時停止する。
		 (let (num)
		   (cond
                     ((null (rest-symbol))
                      (format t "指定した盤面数出力して一時停止します。~%")
                      (format t "Enter number : ")
                      (finish-output)
                      (setq num (read))
                      (clear-input)
                      )
                     ((identity (rest-symbol))
                      ;;(setq num (string-to-integer (first (rest-string))))
                      (setq num (first (rest-symbol)))
                      )
                     ) ;; end cond
		   (if (zero-or-positive-integerp num)
                       (pause num)
                       (do-pause)
                       )
		   (setf show-help nil)
		   ) ;; end let
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'select) ;; ナンプレの問題を選択する。
		 (cond
                   ((null (rest-symbol))
                    (do ((s nil))
			((member s '(a b c d quit q exit) :test #'equal) (setf select s))
                      (format t "A : 盤面データを保存した変数名を入力する。~%")
                      (format t "B : メモリ上にロード済みの盤面データから選ぶ。~%")
                      (format t "C : メモリ上の問題を全て削除する。~%")
                      (format t "D : サンプル問題を復活する。~%")
                      (format t "Select A/B/C/D(中止は\"quit\") : ")
                      (finish-output)
                      (setq s (read))
                      (clear-input)
                      ) ;; end do
                    )
                   ((identity (rest-symbol))
                    (setq select (first (rest-symbol)))
                    )
                   ) ;; end cond

		 (cond
		   ((member select '(quit q exit bye) :test #'equal)
		    (throw 'step-around-loop nil)
		    )
                   ((equal select 'a)
                    (loop
                      (format t "盤面データを保存した変数名を入力して下さい。 ")
                      (finish-output)
                      (setf brd (eval (read)))
                      (clear-input)
                      (cond
			((board-p brd)
			 ;; [examin]→[step-around]→[examin]なので、再度→[step-around]となる。
			 ;; その場合、"Quit"コマンドで[step-around]を終了しても上位の呼び出し元の
			 ;; [step-around]に戻るので再度"Quit"コマンドをタイプしないと実際にquit出来ない。
			 ;; そのため[step-around]内では[examin]を呼び出さず新しいノード設定のみ行って
			 ;; 継続する。
			 ;;(examin brd)
			 (setf node (prepare-step-around brd)) ;; 2024-02-05
			 (return)) ;; exit this loop
			((query-yes-or-no-p "盤面データではありません。~%直接盤面データを入力しますか？")
			 (finish-output)
			 (clear-input)
			 (setf brd (enter-board))
			 (if (null brd)
			     (throw 'step-around-loop nil)
			     ) ;; end inf
			 (setf node (prepare-step-around brd)) ;; 2024-02-05
			 (return) ) ;; exit this loop
			((query-yes-or-no-p "新しいナンプレ問題の設定を止めますか？")
			 (finish-output)
			 (clear-input)
			 (return)) ;; exit this loop
			)          ;; end cond
                      )            ;; end loop
                    )              ;; end (equal select 'a)
             
                   ((equal select 'b)
                    (when (null *sudoku-game-list*)
                      (format t "メモリ上にはナンプレ問題はありません。~%")
                      (format t "\"Read\"コマンドか\"Enter\"コマンドで問題を追加して下さい。~%")
                      )
                    ) ;; end (equal select 'b)

                   ((equal select 'c)
                    ;;(print-colored-string 'red "注意\!\! " 'background-color)
                    (print-colored-string 'red "注意\!\! " :text-or-background 'background-color)
                    (format t "メモリ上の全ての盤面データが消えます。~%")
                    (format t "必要な場合は先に\"Store\"コマンドでファイルに保存して下さい。~%")
                    (when (query-yes-or-no-p "本当に全ての盤面データを消しますか？ ")
                      (setf *sudoku-game-list* nil)
                      )
                    (finish-output)
                    (clear-input)
                    (setf show-help nil)
                    ) ;; end (equal select 'c)

                   ((equal select 'd)
                    (format t "NumberPlace.lispのプログラム本体に登録してあるサンプル問題を復活します。~%")
                    (format t "現在メモリ上に保管されている盤面データに追加されます。~%")
                    (when (query-y-or-n-p "宜しいですか？ ")
                      (setf *sudoku-game-list* (append *sudoku-game-list* *sudoku-game-list-backup*))
                      (setf *sudoku-game-list*
                            (sort (copy-seq *sudoku-game-list*) #'string-lessp
                                  :key #'(lambda (x) (symbol-name (first x)))))
                      )
                    (finish-output)
                    (clear-input)
                    ) ;; end (equal select 'd)

                   ) ;; end cond

		 ) ;; end "N"
		;;---------------------------------------------------------------------------------
		((equal entered-command 'enter)
		 (let (sudoku-name string-name already-interned)
                   (setq sudoku-name (create-unique-name "sudoku-game-")) ;; internされたシンボルが返る。
                   (loop
                     (format t "これから入力する盤面に名前を付けて下さい。~%")
                     (format t "入力を省略すると~aという名前になります(中止は\"quit\")。~%" sudoku-name)
                     (finish-output)
                     (format t "Enter : ")
                     (finish-output)
                     (setq string-name (read-line)) ;; [sudoku-name]=string
                     (clear-input)

		     (if (member (string-upcase string-name) '("QUIT" "Q" "EXIT" "BYE") :test #'string=)
			 (throw 'step-around-loop nil)
			 ) ;; end if

                     (cond
                       ((zerop (length string-name)) ;; 入力省略 --> デフォルト値を選択。
			(setf sudoku-name (enter-board))
			(return)
			)
                       ((plusp (length string-name)) ;; 入力されたシンボル名をinternする。
			(multiple-value-setq (sudoku-name already-interned)
			  (intern (string-upcase string-name)))
			)
                       ) ;; end cond

		     (when (not already-interned)
		       (setf sudoku-name (enter-board))
		       (setq brd (eval sudoku-name))
		       )

		     (when already-interned ;; シンボル名は可視範囲のパッケージ空間に存在済みだった。
		       (if (and ;; 値が束縛されていて、なおかつボード型か？
			    (boundp sudoku-name)
			    (board-p (eval sudoku-name))
			    )
			   (format t "~aというボード型シンボルは既に存在しています。~%" sudoku-name)
			   (format t "~aは値を持っていませんが、既に存在していたシンボルです。~%" sudoku-name)
			   ) ;; end if
                       (format t " A~4t内容を書き換えますか？~%")
                       (format t " B~4t別の名前を考えますか？~%")
                       (format t "Select A or B (中止は\"quit\") : ")
                       (setf select (read))
                       (clear-input)
		       (cond
			 ((member select '(quit q exit bye) :test #'equal) ;; 2024-05-07
			  (throw 'step-around-loop nil)
			  )
			 ((equal select 'a)
			  (setq sudoku-name (enter-board)) ;; overwrite.
			  (setq brd sudoku-name)
			  (return)
			  )
			 ((equal select 'b)
			  (loop
			    (format t "新しい盤面の名前を入力して下さい。: ")
			    (setq sudoku-name (read-line))
			    (multiple-value-setq (sudoku-name already-interned)
			      (intern (string-upcase sudoku-name)))
			    (if (not already-interned)
				(return)
				(format t "既に盤面データとして登録済みの名前です。~%")
				) ;; end if
			    ) ;; end loop
			  (setf sudoku-name (enter-board)) ;; [sudoku-name]に与えられたシンボル名にbindする。
			  (setq brd sudoku-name)
			  )
			 ) ;; end cond
		       ) ;; end when
                     )   ;; end loop

		   (if (or
			(null brd)
			(not (board-p brd))
			)
		       (throw 'step-around-loop nil)
		       ) ;; end if

		   (setq node (prepare-step-around brd))

                   ) ;; end let
		 ) ;; end or
		;;---------------------------------------------------------------------------------
		((equal entered-command 'store)
		 (let (fname default-fname streams tmp)
                   (setf default-fname (name-with-yyyymmdd "sudoku-games-" ".lisp"))
		   (cond
		     ((null (rest-string))
                      (format t "メモリ上に保管されている全ての盤面データをファイルに上書き保存します。~%")
                      (format t "盤面図もコメントとして書き込みます。フルサイズか小型かは設定に従います。~%")
                      (format t "ファイル名を指定して下さい。既定値は(~a) : " default-fname)
                      (finish-output)
                      (setf fname (read-line))
                      (clear-input)
		      )
		     ((identity (rest-string))
		      (setf fname (first (rest-string)))
		      )
		     ) ;; end cond
                   (when (zerop (length fname))
                     (setf fname default-fname)
                     )
                   (setf tmp (color-mode))
                   (color-mode 0) ;; 完全モノクロ=カラー出力のためのエスケープ・シーケンスを出力しない。
                   (finish-output *standard-output*)
                   (setf streams *standard-output*)
                   (with-open-file (s fname :direction :output :if-exists :overwrite
					    :if-does-not-exist :create)
                     (setf *standard-output* s)
                     ;; UTC形式での日付を書き込んでおく。
                     (format s ";; UTC ~a~%" (long-date-and-time-string))
                     (dotimes (i (length *sudoku-game-list*))
                       (setf tmp (nth i *sudoku-game-list*))
                       (format s "\(setq ~a~%~a\)~%" (first tmp) (second tmp))
                       (format s "\#\|~%") ;; comment start
                       (print-board (pm (second tmp)))
                       (format s "\|\#~%") ;; end comment
                       )                   ;; end dotimes
                     (finish-output s)
                     ) ;; end with-open file
                   (setf *standard-output* streams)
                   (finish-output)
                   (color-mode tmp)
                   (format t "ファイル ~a に保存しました。~%" fname)
                   ) ;; end let
		 (setf show-help nil)
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'read)
		 (let (fname default-fname prefix-name result)

                   (setf default-fname (name-with-yyyymmdd "sudoku-games-" ".lisp"))
                   (setf prefix-name "sudoku-game-")

                   (cond
                     ((null (rest-symbol))
                      (format t "どのファイルから読み込みますか\(~a\)？~%" default-fname)
                      (format t "盤面は通常の2次元配列形式に加えて81桁の数字列形式にも対応しています。~%")
                      (format t "名前のない盤面だけのデータは自動的に名前を与えて読み込みます。~%")
                      (finish-output)
                      (format t "Enter filename : ")
                      (finish-output)
                      (setq fname (read-line))
                      (clear-input)
                      )
                     ((identity (rest-symbol))
                      (setf fname (second (original-read-string-list)))
                      )
                     ) ;; end cond

                   (when (zerop (length fname))
                     (setf fname default-fname)
                     )

                   ;; 読み込む盤面データに無名のものがあった場合に自動的に名前を与えながら読み込む。
                   ;; 名前は[prefix-name]+[数字列]となりinternされている。名前の一意性は保証されている。
		   ;; [数字列]部分の数値は連番とは限らない。
                   (setq result (select-game-from-file fname (select-prefix-name prefix-name)))
		   (cond
		     ((null result)
		      (format t "盤面データは存在しませんでした。~%")
		      (return-from step-around nil)
		      )
		     ((board-p result)
		      (prepare-step-around result)
		      )
		     ) ;; end cond
                   ) ;; end let
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'collection) ;; 現在のノードの盤面をファイルに追加保存する。
		 (let (fname board-name stream c-mode)
		   (cond
		     ((null (rest-symbol))
                      (format t "追記するファイル名\(~a\)を指定して下さい。"
                              (name-with-yyyymmdd (default-node-data-fname-prefix) ".lisp"))
                      (finish-output)
                      (setf fname (read-line))
                      (clear-input)
                      (when (zerop (length fname))
			;; "sudoku-YYYYMMDD.lisp" ファイル。
			(setf fname (name-with-yyyymmdd (default-node-data-fname-prefix) ".lisp"))
			)
		      )
		     ((identity (rest-symbol)) ;; 先行入力があった。
		      (setf fname (name-with-yyyymmdd (second (original-read-string-list)) ".lisp"))
		      )
		     ) ;; end cond
		   (cond
		     ((< (length (rest-symbol)) 2)
                      (format t "保存する盤面に名前を付けて下さい。")
                      (finish-output)
                      (setf board-name (read-line))
                      (clear-input)
                      (when (zerop (length board-name))
			(setf board-name
                              (format nil "board-~a-~a" (short-date-string)
                                      (game-node-node-number node)))
			(format t "~a という名前で保存します。~%" board-name)
			(finish-output)
			)
		      )
		     ((>= (length (rest-symbol)) 2) ;; 2つ目の先行入力もあった。
		      (setf board-name (third (original-read-string-list)))
		      (setf board-name
			    (format nil "board-~a-~a" (short-date-string) (game-node-node-number node)))
		      )
		     ) ;; end second cond

                   ;;(pure-save-data tmp fname t)
                   (setf c-mode (color-mode))
                   (color-mode 0) ;; 完全モノクロ=カラー出力のためのエスケープ・シーケンスを出力しない。
                   (finish-output *standard-output*)
                   (setf stream *standard-output*)
                   (with-open-file (s fname :direction :output :if-exists :append
					    :if-does-not-exist :create)
                     (setf *standard-output* s)
                     (format s "\;\; UTC ~a~%" (iso8601-date-string 'long 'date-and-time))
                     ;;(setf tmp (format nil "~a~%" (game-node-present-board node)))
                     ;;(setf tmp (format nil "\(setq ~a~%~a\)~%" board-name tmp))
                     (format s (format nil "\(setq ~a~%~a\)~%" board-name
                                       (game-node-present-board node)))
                     (format s "\#\|~%") ;; comment start
                     ;; 盤面図もコメントとして書き込む。
                     (print-board (pm (game-node-present-board node)))
                     (format s "\|\#~%") ;; end comment
                     (finish-output s)
                     )
                   (setf *standard-output* stream)
                   (finish-output)
                   (format t "*Saves ~a~%" (truename fname))
                   (finish-output)
                   (color-mode c-mode)
                   (setf show-help nil)
                   ) ;; end let
		 )
		;;---------------------------------------------------------------------------------
		((and
                  (equal entered-command '\>\>\>) ;; 盤面に矛盾が生じたケースのデータを保存する。
                  (allow-for-debug-command)
                  ;;(inconsistent-case)
                  )
		 (let (fname)
                   (format t "矛盾したケースを追記するファイル名\(省略時=~a\)を指定して下さい。"
                           (name-with-yyyymmdd "inconsistent-" ".data"))
                   (finish-output)
                   (setf fname (read-line))
                   (clear-input)
                   (when (zerop (length fname))
                     ;; create "inconsistent-YYYYMMDD.data" ファイル。
                     (setf fname (name-with-yyyymmdd "inconsistent-" ".data"))
                     )
                   (pure-save-data (format nil "~a~%" (inconsistent-case)) fname t)
                   )
		 )
		;;---------------------------------------------------------------------------------
		((and
                  (equal entered-command '\$\$\$)
                  (allow-for-debug-command)
                  ;;(inconsistent-case)
                  )
		 (format t "以下の ~d 個のケースで矛盾が生じました。~%" (length (inconsistent-case)))
		 (finish-output)
		 (dolist (s (inconsistent-case))
                   (print-board (first s))
                   (format t "ノード \#~d に手筋 ~a を適用したケース。~%~%"
                           (third s)
                           (function-name-to-tesuji-name (second s))
                           ;;(cdr (assoc (second s) (function-name-to-tesuji-name-list)))
                           )
                   ) ;; end dolist
		 )
		;;---------------------------------------------------------------------------------
		;; 全ての解法過程ルートを探索する。盤面によっては大量のメモリとCPU時間を要する。
		((and
                  (equal entered-command 'explore)
                  (allow-explore))
		 (let (minutes start-time elapsed-time)
		   (if (null (rest-string))
		       (progn
			 (print-repeated-char-string 70 #\=)
			 (format t "現在のノードに対する全ての解法過程ルートを探索します。~%")
			 (format t "変化の多い複雑な盤面の場合、数時間以上かかる可能性があります。~%")
			 (format t "一定の分数ごとに探索を続けるかどうかを設定できます(自動一時停止)。~%")
			 (format t "非負整数を入力して下さい。ゼロを指定すると中断なしです(お薦めしません)。~%")
			 (format t "自動保存を設定しておくと指定した時間(分単位)毎に上書き保存します。~%")
			 (format t "自動一時停止と自動保存の両方が設定されていると自動一時停止のみ行います。~%")
			 (format t "自動一時停止中に処理の継続方法を変更できます。~%")
			 (print-repeated-char-string 70 #\=)
			 (format t "何分おきに一時停止しますか？ ")
			 (finish-output)
			 (setf minutes (read)) ;; 分数、浮動点数での入力も可。
			 (clear-input)
			 (if (member minutes '(quit q exit bye) :test #'equal)
			     (throw 'step-around-loop nil)
			     ) ;; end if
			 ) ;; end progn
		       ;; else if section
		       ;; 先行入力があった。先行入力でも、分数、浮動点数での入力を受け付ける。
		       (with-input-from-string (stream (first (rest-string)) :start 0)
			 (do* ((eos (cons nil nil))
			       (num (read stream nil eos) (read stream nil eos)))
			      ((eq num eos) num)
			   (setf minutes num) ;; 数値以外が入力される可能性が残っている。
			   )		      ;; end do*
			 ) ;; end with-input-from-string
		       )   ;; end if

		   (debug-write "step-around-explore"
				(format nil "minutes=~d (numberp minutes)=~a~%" minutes (numberp minutes)))

		   (cond
                     ((and
		       (numberp minutes)
		       (zerop minutes)
                       (query-yes-or-no-p "本当に一時停止なしで良いですか？") ;; 最終確認。
		       )
                      (finish-output)
                      (clear-input)
                      (when (plusp (auto-save-minutes)) ;
			(format t "~d 分ごとに途中経過を保存します。~%" (auto-save-minutes))
			(finish-output)
			) ;; end when
		      (setf start-time (get-internal-real-time))
                      (find-all-logical-path (root-node) 0) ;; 一時停止なしで実行。
                      )					    ;; end and
                     ((and
                       (numberp minutes)
                       (plusp minutes))
		      (setf start-time (get-internal-real-time))
                      (find-all-logical-path (root-node) minutes) ;; [minutes]分ごとに一時停止。
                      ) ;; end and
                     )  ;; end cond

		   (setf elapsed-time (- (get-internal-real-time) start-time))
		   (format t "...終了しました(~,4,,f sec)。~%"
			   (float (/ elapsed-time internal-time-units-per-second)))
		   (finish-output)
		   (if (plusp (auto-save-minutes)) (save-node-data (root-node)))
		   (print-way-to-goal (root-node) 'next-node-null)
		   ) ;; end let
		 )   ;; end "E"
		;;---------------------------------------------------------------------------------
		((equal entered-command 'output)
		 (let (fname)
		   (cond
                     ((null (rest-symbol)) ;; 先行入力がなかった。
                      (format t  "全ての解法ルート図をファイルに保存します。~%")
                      (when (query-y-or-n-p "宜しいですか？ ")
			(finish-output)
			;;(clear-input)
			(format t "保存するファイル名を入力して下さい。~%省略時は ~a となります。 "
				(name-with-yyyymmdd "LogicalPath-" ".txt"))
			(finish-output)
			(setf fname (read-line))
			(clear-input)
			(cond
			  ((zerop (length fname))
			   (save-way-to-goal (root-node) 'next-node-null))
			  (t (save-way-to-goal (root-node) 'next-node-null fname))
			  ) ;; end cond
			)   ;; end when
                      )
                     ((identity (rest-symbol)) ;; 先行入力があった。
                      (save-way-to-goal (root-node) 'next-node-null (second (original-read-string-list)))
                      )
                     ) ;; cond
		   )   ;; end let
		 )   ;; end "O"
		;;---------------------------------------------------------------------------------
		((and
                  (equal entered-command 'auto)
                  (allow-explore)
		  )
		 (cond
		   ((null (rest-symbol))
		    (format t "現在のルート探索経過自動書き込み時間は ~d 分です。~%" (auto-save-minutes))
		    (format t "*自動書き込み間隔(分単位)を入力して下さい。 ")
		    (finish-output)
		    (auto-save-minutes (read))
		    (clear-input)
		    )
		   ((identity (rest-symbol))
		    (auto-save-minutes (first (rest-symbol)))
		    )
		   ) ;; end cond
		 (setf show-help nil)
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'help) ;; ヘルプ・コマンド
		 (setq show-help nil)
		 (loop
                   (select-methods-help)
                   (finish-output)
                   (if (not (query-y-or-n-p "別の手筋の解説を続けて読みますか？ ")) (return))
                   ) ;; end loop
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'version)
		 (format t "Version ~a~%" (numberplace-version))
		 (finish-output)
		 (setf show-help nil)
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'level)
		 (let (local-commands quit-commands entered select sym)
		   (setq local-commands '(novice middle senior advanced machine help))
		   (setq quit-commands '(quit exit bye))
		   (setq entered nil)
		   (cond
		     ((null (rest-symbol)) ;; 先行入力がなかった。
		      ;;(do ((s nil))
		      ;;((member s local-commands :test #'equal)
		      ;; (setf select s)
		      ;; )
		      (loop
			(format t "使用許可する手筋の種類と制約を次の4段階から選んで下さい。~%")
			(format t "~4t N)ovice   : 初心者向き設定~%")
			(format t "~4t Mi)ddle   : 中級者向き設定~%")
			(format t "~4t S)enior   : 中〜上級者向き設定~%")
			(format t "~4t A)dvanced : 上級者向き設定~%")
			(format t "~4t Ma)chine  : 超上級者向き設定~%")
			(format t "~4t H)elp     : レベル基準の表示~%")
			(format t "Enter : ")
			(finish-output)
			(setq sym (read-multiple-symbol))
			(setq entered (get-command-full-name sym (append local-commands quit-commands)))
			(clear-input)

			(cond
			  ((and
			    (zerop (length entered))
			    (null sym)
			    )
			   (format t "メニュー内のいずれかのコマンドを入力して下さい。~%")
			   )
			  ((and
			    (zerop (length entered))
			    (identity sym)
			    )
			   (format t "メニューに存在しないコマンドです(~a)。~%" sym)
			   )
			  ((and
			    (= (length entered) 1) ;; 入力したコマンドが確定。
			    (not (equal (first entered) 'help))
			    )
			   (setq select (first entered))
			   (if (member select quit-commands :test #'equal)
			       (throw 'step-around-loop nil)
			       ) ;; end if
			   (return) ;; exit this loop.
			   )
			  ((and ;; helpコマンドは別枠。
			    (= (length entered) 1)
			    (equal (first entered) 'help)
			    )
			   (print-repeated-char-string 50 #\-)
			   (terpri)
			   (format t "Novice:~tlocalization=No,n-grid=No,tuples=No,配置確定法=No~%")
			   (format t "Middle:~tlocalization=Yes,n-grid=No,tuples=2国同盟まで,配置確定法=No~%")
			   (format t "Senior:~tlocalization=Yes,n-grid=2x2(x-wing)まで,tuples=3国同盟まで~%")
			   (format t "~8t配置確定法=No~%")
			   (format t "Advanced:~tlocalization=Yes,n-grid=3x3(swordfish)まで, tuples=3国同盟まで~%")
			   (format t "~8t配置確定法=Yes,ALS=Yes,Nice Loop=連鎖セル数5まで~%")
			   (format t "Machine:~tlocalization=Yes,n-grid=上限なし,tuples=上限なし~%")
			   (format t "~8t配置確定法=Yes, ALS=Yes,Nice Loop=上限なし,Advanced Coloring=Yes~%")
			   (format t "~8tGB-ALS=Yes,cheat=許可,複数解=探索せず~%")
			   (print-repeated-char-string 50 #\-)
			   (terpri)
			   )
			  ((>= (length entered) 2) ;; 入力文字が足りず複数のコマンドが対象として残っている。
			   (format t "入力した ~a だけでは、どのコマンドか特定できません~a。~%"
				   entered
				   (mapcar #'(lambda (x) (string-capitalize (symbol-name x))) local-commands)
				   ) ;; end format
			   )
			  ) ;; end cond

			(debug-write "examin-level" (format nil "select=~s~%" select))
			) ;; end loop
		      )
		     ((identity (rest-symbol)) ;; 先行入力があった。
		      (setq select (get-command-full-name (first (rest-symbol)) local-commands))
		      )
		     ) ;; end cond
		   )   ;; end let
		 (cond
		   ((equal select 'novice)
                    ;;(long-message-print)
                    ;;(ignore-show-help nil)
		    (novice-level)
		    )
		   ((equal select 'middle)
		    ;;(normal-message-print)
                    ;;(ignore-show-help nil)
		    (middle-level)
		    )
		   ((equal select 'senior)
		    ;;(normal-message-print)
                    ;;(ignore-show-help nil)
		    (senior-level)
		    )
		   ((equal select 'advanced)
		    ;;(minimum-message-print)
                    ;;(ignore-show-help nil)
		    (advanced-level)
		    )
		   ((equal select 'machine)
		    ;;(minimum-message-print)
                    ;;(ignore-show-help nil)
		    (machine-level)
		    )
		   (t
		    (format t "Levelコマンド : 正しいキーワードが入力されませんでした ~a。~%" select)
		    (format t "メイン・メニューからレベル指定部を先行入力した際にスペルミスしています。~%")
		    )
		   ) ;; end cond
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'menu)
		 (let (local-commands quit-commands sym-list)
		   (setq local-commands '(verbose normal minimum command))
		   (setq quit-commands '(quit exit bye))
		   (cond
		     ((null (rest-symbol))
		      (do ((s nil))
			  ((and
			    (= (length s) 1)
			    (member (first s) local-commands :test #'equal)
			    )
			   (setf select (first s)))
			(format t "メニューの表示量を次の3段階から選んで下さい。~%")
			(format t "~4t V)erbose : 詳細~%")
			(format t "~4t N)ormal  : 通常~%")
			(format t "~4t M)inimum : 最小~%")
			(format t "~4t C)ommand : なし~%")
			(format t "Select V/N/M/C : ")
			(finish-output)
			(setq s (get-command-full-name (read) (append local-commands quit-commands)))
			(clear-input)
			(cond
			  ((zerop (length s))
			   (format t "~aのいずれかを入力して下さい。~%" local-commands)
			   )
			  ((= (length s) 1)
			   (when (member (first s) quit-commands :test #'equal)
			     (throw 'step-around-loop nil)
			     (do-nothing)
			     ) ;; end when
			   )
			  ((>= (length s) 2)
			   (format t "入力した ~a だけでは、どのコマンドか特定できません~a。~%"
				   s local-commands
				   )
			   )
			  ) ;; end inner cond
			)   ;; end do
		      (debug-write "step-around-menu" (format nil "select=~a~%" select))
		      )
		     ((identity (rest-symbol)) ;; 先行入力があった。
		      (setq sym-list (get-command-full-name (first (rest-symbol)) local-commands))
		      (cond
			((and ;; 万が一、(first (rest-symbol))に明示的な[nil]が指定されていた場合の備え。
			  (zerop (length sym-list))
			  (null (first (rest-symbol)))
			  )
			 (format t "メニュー内のいずれかのコマンドを入力してください。~%")
			 )
			((and
			  (zerop (length sym-list))
			  (identity (first (rest-symbol)))
			  )
			 (format t "メニューに存在しないコマンドです(~a)。~%" (first (rest-symbol)))
			 )
			((= (length sym-list) 1)
			 (setq select (first sym-list))
			 )
			((>= (length sym-list) 2) ;; 先頭1文字が異なっているので現状あり得ない。将来への備え。
			 (format t "入力した ~a だけでは、どのコマンドか特定できません~a。~%"
				 (first (rest-symbol)) (mapcar #'string-capitalize sym-list))
			 )
			) ;; end inner cond
		      )
		     ) ;; end cond

		   (cond
                     ((equal select 'verbose)
                      (long-message-print)
                      (ignore-show-help nil)
                      )
                     ((equal select 'normal)
                      (normal-message-print)
                      (ignore-show-help nil)
                      )
                     ((equal select 'minimum)
                      (minimum-message-print)
                      (ignore-show-help nil)
                      )
                     ((equal select 'command)
                      (no-message-print)
                      (format t "再度メニューを表示するには \"Menu[return]\" と入力します。~%")
                      (format t "Verbose表示モードで表示される全てのメニュー・コマンドが使えます。~%")
                      (finish-output)
                      )
		     (t
		      (format t "menuコマンド : 正しいキーワードが入力されませんでした。~%")
		      (format t "メイン・メニューからレベル指定部を先行入力した際にスペルミスしています。~%")
		      )
                     ) ;; end cond
		   )   ;; end let
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'eval)
		 (let (sym help-list fname streams)

		   (cond
		     ((null (rest-symbol)) ;; read-multiple-symbolで読み込んでいる。
		      (format t "Enter S-Exp (\"help\"で各種初期設定用関数のヘルプ) : ")
		      (finish-output)
		      (setq sym (read-multiple-symbol)) ;; シンボルとして読み込む。
		      (clear-input)
		      (cond
			((member sym '(help h) :test #'equal)
			 (setq help-list
			       '(als-show-all als-show-stat gb-als-show-all capital-address color-mode
				 need-multiple-answer print-color-sample sel tuples-limit n-grid-limit
				 min-nice-length max-nice-length novice-level middle-level senior-level
				 advanced-level machine-level))
			 (format t "主な動作初期設定用関数の一覧。~%")
			 (format t "毎回同じ設定にしたい場合はホーム・ディレクトリの")
			 (format t "\"NumberPlace-init\.lisp\"に書き込んでおく。~%")
			 (dolist (msg help-list)
			   (print-repeated-char-string 72 #\-)
			   (format t "~a~%" msg)
			   (help-for msg)
			   )
			 (when (and ;; help lprと入力されていたらプリンタにも出力する。
				(identity (rest-symbol))
				(member (first (rest-symbol)) '(lpr print pr) :test #'equal)
				)
			   ;; 年月日時分秒からなるファイル名を作成。
			   (setq fname (iso8601-date-string 'long 'date-and-time))
			   (finish-output *standard-output*)
			   (setq streams *standard-output*)
			   (with-open-file
			       (s fname :direction :output :if-exists :overwrite :if-does-not-exist :create)
			     (setq *standard-output* s)
			     (format t ";; ~a~%~%" fname)
			     (dolist (msg help-list)
			       (print-repeated-char-string 72 #\-)
			       (format t "~a~%" msg)
			       (help-for msg)
			       ) ;; end dolist
			     (finish-output s)
			     ) ;; end with-open-file
			   (setq *standard-output* streams)
			   (finish-output)
			   (external-lpr fname)
			   (delete-file fname) ;; 外部コマンドで印刷するために作成したファイルを削除。
			   )
			 )
			(t
			 (format t "~a~%" (eval sym))
			 (dolist (s (rest-symbol))
			   (format t "~a~%" (eval s))
			   ) ;; end dolist
			 )
			) ;; end cond
		      )	  ;; end (null (rest-string))
		     ((identity (rest-symbol))
		      ;;(dolist (s (rest-string)) ;; 読み込んだ文字列をシンボルに変換。
			;;(with-input-from-string (p s)
			;;  (setq sym (read p nil eos))
			;;  (if (eq sym eos) (return)) ;; exit dolist
			;;  (push sym result)
			;;  ) ;; end with-input-from-string
			;;)   ;; end dolist
		      ;;(setq result (reverse result))
		      ;;(dolist (s result) ;; 変換したシンボルを全て評価して印字する。
		      (dolist (s (rest-symbol))
			(format t "~a~%" (eval s))
			) ;; end dolist
		      )
		     ) ;; end cond
		   ) ;; end let
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'quit)
		 (finish-output)
		 (clear-output)
		 (return-from step-around-loop-block t) ;; exit and (restore-env)
		 )
		;;---------------------------------------------------------------------------------
		((equal entered-command 'lpr)
		 (let (n dest-node current-node brd tmp tmp-2 fname streams node-label do-lpr)
		   (finish-output) ;; for sbcl
		   (setq current-node node)
		   (setq do-lpr nil)
		   (block lpr-block
		     (cond
		       ((null (rest-symbol)) ;; 先行入力がなかった。
			(loop
			  (loop
			    (format t "印刷する盤面のノード番号を入力してください(中止は\"quit\")。: ")
			    (finish-output)
			    (setf n (read))
			    (clear-input)
			    (if (member n '(quit q exit bye) :test #'equal)
				(return-from lpr-block nil)
				) ;; end if
			    (if (not (integerp n))
				(progn
				  (format t "ノード番号(数値)を入力してください。~%")
				  (finish-output)
				  )    ;; end progn
				(return) ;; exit loop
				)	 ;; end if
			    )		 ;; end loop
			  (finish-output)
			  (setq dest-node (find-node n))
			  (if (null dest-node)
			      (progn
				(format t "存在するノード番号を入力してください。~%")
				(finish-output)
				)    ;; end progn
			      (return) ;; exit loop
			      )	       ;; end if
			  )	       ;; end outer loop
			)
		       ((identity (rest-symbol)) ;; 先行入力があった。
			(setq n (first (rest-symbol)))
			(if (integerp n)
			    (setq dest-node (find-node n))
			    ) ;; end if
			(when (null dest-node)
			  (format t "先行入力で指定されたノード番号(~d)は存在しません。~%" n)
			  (return-from lpr-block nil)
			  ) ;; end when
			(setq do-lpr t)
			) ;; end 先行入力処理
		       )  ;; end cond
		     (finish-output)

		     (setf brd (new-board (game-node-present-board dest-node)))
		     (setf node-label (game-node-node-label dest-node))
		     (when (null do-lpr) ;; 先行入力で印刷指定があったときは盤面の確認表示も省略。
		       (format t "#~d(~a)~%" n node-label)
		       (print-normal (pm brd))
		       (finish-output)
		       ) ;; end when
		     (when (or
			    (identity do-lpr)
			    (query-y-or-n-p "印刷しますか？ ")
			    )
		       (finish-output)
		       ;; 年月日時分秒からなるファイル名を作成。
		       (setf fname (iso8601-date-string 'long 'date-and-time))
		       (finish-output *standard-output*)
		       (setf streams *standard-output*)
		       (with-open-file
			   (s fname :direction :output :if-exists :overwrite :if-does-not-exist :create)
			 (setf *standard-output* s)
			 (setf tmp (color-mode))
			 (setf tmp-2 (pause))
			 (color-mode 0)
			 (pause 0)
			 (format s "#~d(~a)~%" n node-label)
			 (print-normal brd)
			 (finish-output s)
			 (color-mode tmp)
			 (pause tmp-2)
			 )
		       (setf *standard-output* streams)
		       (finish-output)
		       (external-lpr fname)
		       (delete-file fname) ;; 外部コマンドで印刷するために作成したファイルを削除。
		       )		   ;; end when
		     )			   ;; end lpr-block
		   (setq node current-node)
		   ) ;; end let
		 )   ;; end or
		;;---------------------------------------------------------------------------------
		(t
		 (format t "*Please select one of above or number~%")
		 (finish-output)
		 )
		;;---------------------------------------------------------------------------------
		) ;; end first cond
              (clear-input *standard-input*)
              (clear-input *terminal-io*)
	      ) ;; end catch
            )	;; end loop
      )	      ;; end block of step-around-loop-block
    (restore-env)
    (return-from step-around t)
    ) ;; end let
  ) ;; end step-around

(defun step-around-menu-list ()
  (return-from step-around-menu-list *step-around-menu-list*)
  )

(defun get-command-full-name (sym command-list)
  "[sym]と部分一致する[command-list]内のシンボルのリストを返す。
(get-command-full-name 'a '(auto information guess explore eval)) ==> (auto)
(get-command-full-name 'xxx '(auto information guess explore eval)) ==> nil
(get-command-full-name 'e '(auto information guess explore eval)) ==> (explore eval)
(get-command-full-name nil '(auto information guess explore eval)) ==> nil
"
  (let (result search-result str q)
    (setq result nil)
    (setq str (string-upcase (symbol-name sym))) ;; 大文字・小文字を区別する"modern"スタイル対策。
    (dolist (p command-list)
      (setq q (string-upcase (symbol-name p)))
      (setq search-result (search str q :test #'string= :start1 0 :start2 0))
      (if (and (integerp search-result) (zerop search-result))
	  (push p result)
	  ) ;; end if
      ) ;; end dolist
    (return-from get-command-full-name (reverse result))
    ) ;; end let
  ) ;; end get-command-fule-name

(defun shortest-command-name (command-name command-list)
  "複数のコマンド名を含む[command-list]から[command-name]を識別するために必要な最短文字数の名前を返す。
(shortest-command-name 'auto  '(auto information guess explore eval)) ==> 'a
(shortest-command-name 'eval  '(auto information guess explore eval)) ==> 'ev
"
  (let (first-step-list result i tmp)
    (setq first-step-list nil)
    (dolist (p command-list) ;; 最初の1文字が一致するコマンドのリストを作る。
      (setq tmp (search (subseq (symbol-name command-name) 0 1) (symbol-name p) :test #'char=))
      ;;(format t "first-search-tmp=~a~%" tmp)
      (if (and
	   (integerp tmp)
	   (zerop tmp)
	   )
	  (push p first-step-list)
	  ) ;; end if
      )	    ;; end dolist

    (debug-write "shortest-command-name" (format nil "first-step-list=~a~%" first-step-list))

    (cond
      ((zerop (length first-step-list))
	(return-from shortest-command-name nil)
	)
      ((= (length first-step-list) 1)
       (return-from shortest-command-name (intern (subseq (symbol-name command-name) 0 1)))
       )
      ) ;; end cond

    (setq i 2) ;; (length first-step-list) >= 2
    (setq result nil)
    (loop
      (dolist (p first-step-list)
	(setq tmp (search (subseq (symbol-name command-name) 0 i) (symbol-name p)
			  :test #'string= :start1 0 :start2 0))
	(debug-write "shortest-command-name-2"
		     (format nil "(subseq ~a 0 ~d)=~a, tmp=~a, p=~a~%" command-name i
			     (subseq (symbol-name command-name) 0 i) tmp p))
	(if (and
	     (integerp tmp)
	     (zerop tmp)
	     )
	    (push (subseq (symbol-name command-name) 0 i) result)
	    ) ;; end if
	)     ;; end dolist
      (if (= (length result) 1)
	  (return) ;; exit this loop.
	  )
      (incf i)
      ) ;; end loop
    (return-from shortest-command-name (intern (first result)))
    ) ;; end let
  ) ;; end shortest-command-name

(defun make-shortest-command-name-list (command-list &key ((:pair pair) nil))
  "[command-list]に含まれるコマンド名を識別するための最短文字のコマンド名のリストを返す。

[251]> (step-around-menu-list)
(auto board change collection description dribble enter eval explore find goal guess help
 information level load lpr menu output pause quit read route save select store tesuji up
 version >>> $$$)
[252]> (make-shortest-command-name-list (step-around-menu-list))
(a b ch co de dr en ev ex f go gu h i le lo lp m o p q re ro sa se st t u v > $)

[253]> (make-shortest-command-name-list (step-around-menu-list) :pair t)
((auto . a) (board . b) (change . ch) (collection . co) (description . de) (dribble . dr)
 (enter . en) (eval . ev) (explore . ex) (find . f) (goal . go) (guess . gu) (help . h)
 (information . i) (level . le) (load . lo) (lpr . lp) (menu . m) (output . o)
 (pause . p) (quit . q) (read . re) (route . ro) (save . sa) (select . se) (store . st)
 (tesuji . t) (up . u) (version . v) (>>> . >) ($$$ . $))
"
  (let (result)
    (setq result nil)
    (dolist (p command-list)
      (if (null pair)
	  (push (shortest-command-name p command-list) result)
	  (push (cons p (shortest-command-name p command-list)) result)
	  ) ;; end if
      ) ;; end dolist
    (return-from make-shortest-command-name-list (reverse result))
    ) ;; end let
  )

(defun make-menu-name-list (&key ((:menu-name-list menu-name-list) (step-around-menu-list))
			       ((:front front) nil) ((:end end) nil))
  "メニュー・コマンド名の一覧を受け取って最短文字数で区別できる位置に\"\)\"を挿入したコマンド名文字列のリストを返す。
先頭と末尾に追加したい文字列があれば[:front \"front\"]と[:end \"end\"]のように追加指定する。
[276]> (step-around-menu-list)
(auto board change collection description dribble enter eval explore find goal guess help
 information level load lpr menu output pause quit read route save select store tesuji up
 version >>> $$$)
[277]> (make-menu-name-list (step-around-menu-list))
((auto . \"A)uto\") (board . \"B)oard\") (change . \"Ch)ange\") (collection . \"Co)llection\")
 (description . \"De)scription\") (dribble . \"Dr)ibble\") (enter . \"En)ter\")
 (eval . \"Ev)al\") (explore . \"Ex)plore\") (find . \"F)ind\") (goal . \"Go)al\")
 (guess . \"Gu)ess\") (help . \"H)elp\") (information . \"I)nformation\") (level . \"Le)vel\")
 (load . \"Lo)ad\") (lpr . \"Lp)r\") (menu . \"M)enu\") (output . \"O)utput\") (pause . \"P)ause\")
 (quit . \"Q)uit\") (read . \"Re)ad\") (route . \"Ro)ute\") (save . \"Sa)ve\")
 (select . \"Se)lect\") (store . \"St)ore\") (tesuji . \"T)esuji\") (up . \"U)p\")
 (version . \"V)ersion\") (>>> . \">)>>\") ($$$ . \"$)$$\"))

"
  (let (command-name-pair-list tmp result)
    (setq result nil)
    (setq command-name-pair-list (make-shortest-command-name-list menu-name-list :pair t))
    (dolist (p command-name-pair-list)
      (setq tmp (subseq (symbol-name (car p)) (length (symbol-name (cdr p)))))
      (debug-write "make-menu-name-list" (format nil "tmp-1=~s~%" tmp))
      (setq tmp (concatenate 'string (string-capitalize (symbol-name (cdr p))) ")" (string-downcase tmp)))
      (debug-write "make-menu-name-list" (format nil "tmp-2=~s~%" tmp))
      (when (stringp front)
	(setq tmp (concatenate 'string front tmp))
	)
      (when (stringp end)
	(setq tmp (concatenate 'string tmp end))
	)
      (push (cons (car p) tmp) result)
      ) ;; end dolist
    (return-from make-menu-name-list (reverse result))
    ) ;; end let
  ) ;; end make-menu-name-list

(defun menu-name (command-name &optional (menu-name-pair-list *menu-name-pair-list*))
  "[command-name]に与えられたコマンド名(フルネーム)を[menu-name-list]内のコマンド群から最短文字数で区別するために必要な文字部分を\"\)\"で区切って示す文字列を返す。[:front]と[:end]には前後に追加したい文字列があれば指定する。
[285]> (menu-name 'auto)
\"A)uto\"
[286]> (menu-name 'e)
nil
[287]> (menu-name 'eval)
\"Ev)al\"
"
  (cdr (assoc command-name menu-name-pair-list))
  ) ;; end menu-name

(defun prompt-string ()
  (format nil "\*\(~a\/~a ~a\) Select menu : "
	  (lisp-implementation-type)
	  ;;(lisp-implementation-version)
	  (machine-type)
	  ;;(software-type)
	  (iso8601-date-string 'long 'time-only)
	  )
  )

(defun print-methods (node)
"引数で与えられたノード[node]の盤面に適用可能な手筋の一覧を表示する。"
  (let (current-node-number tesuji-exist)

    ;;(format t "print-methods : node=~s~%" node)
    ;; create and set child nodes for [node].
    (if (null (game-node-next-node node)) (setf node (create-generation node)) )

    (finish-output)
    (when (or (long-explanation) (normal-explanation))
      (format t "==============================~%") 
      (format t "適用可能な手筋は次の通りです。~%")
      (format t "==============================~%") 
      )
    (setf current-node-number (game-node-node-number node)) ;; 現ノードの番号
    ;;(format t "current-node-number=~d~%" current-node-number)
    ;;(format t "current node=~s~%" node)
    (setf tesuji-exist nil)
    (dolist (p (reverse (game-node-next-node node)))
      (when (member (game-node-state p) '(finished applied))
        (setf tesuji-exist t)
        (format t (concatenate 'string "  \#~d " *normal-shaft-string* "> \#~d (~s) ~a (~a)~%")
                current-node-number
                (game-node-node-number p)
                (game-node-node-label p)
                (function-name-to-tesuji-name (game-node-prev-methods p))
                (game-node-state p) )
        ) ;; end when
      )   ;; end dolist
    (when (null tesuji-exist)
      (format t "この盤面に対して適用できる手筋はありませんでした。~%")
      (return-from print-methods nil)
      )
    (return-from print-methods t)
    ) ;; end let
  )

(defun get-quiz-info-list (node)
"指定されたノードの子ノードに登録されている[quiz-info]にノード番号を加えたリストのリストを返す。2024-02-25

[quiz-info-list] ::= ( ([ノード番号] (([手筋情報]+))* ) ) ;
[solution-info]  ::= ([手筋情報]+) ;
[手筋情報]       ::= ([手筋関数名] [成立理由] [位置条件] [位置リスト]) ;
[手筋関数名]     ::= [手筋関数名シンボル] ;
[成立理由]       ::= [文字列] | [シンボル] ;
[位置条件]       ::= ('and [位置条件]+) | ('or [位置条件]+) |
                    ('not [位置条件]+) | [位置条件要素] ;
[位置条件要素]   ::= [cell] | [row] | [col] | [block] | [house] | [chain] | [group] ;
[cell]          ::= ([行番号] [列番号]) ;
[row]           ::= ('row [行番号]) ;
[col]           ::= ('col [列番号]) ;
[block]         ::= ('block [ブロック番号]) ;
[house]         ::= ('house [cell]) ; [cell]を含むハウス。
[chain]         ::= ('chain [cell]+) ;
[削除/確定情報] ::= ({'mustbe | 'cannotbe} (row col) {[candidate] | ([candidate]+)) ;
[位置リスト]    ::= ([削除/確定情報]+) ;"
  (let (quiz-info-list current-node-number child-nodes)
    (if (not (typep node 'game-node)) (return-from get-quiz-info-list nil))
    (setf quiz-info-list nil)
    (when (null (game-node-seen node)) ;; 未訪問ならば登録された全ての手筋を適用して情報を揃える。
      (setf node (create-generation node))
      )
    (setf current-node-number (game-node-node-number node))
    (setf child-nodes (game-node-next-node (find-node current-node-number)))
    (dolist (p child-nodes)
      (when (member (game-node-state p) '(finished applied) :test #'equal)
        (push (cons (game-node-node-number p) (reverse (game-node-quiz-info p))) quiz-info-list)
        ) ;; end when
      ) ;; end dolist
    (return-from get-quiz-info-list quiz-info-list)
    ) ;; end let
  )

(defun get-parent-node-from-quiz-info-list (quiz-info-list)
  "[quiz-info-list]から親ノードを取り出して返す。"
  (if (null quiz-info-list) (return-from get-parent-node-from-quiz-info-list nil))
  (return-from get-parent-node-from-quiz-info-list
    (parent-node (find-node (first (first quiz-info-list)))))
  )

(defun get-parent-board-from-quiz-info-list (quiz-info-list)
  "[quiz-info-list]から親ノードに登録されている盤面を取り出して返す。"
  (return-from get-parent-board-from-quiz-info-list
    (game-node-present-board (get-parent-node-from-quiz-info-list quiz-info-list)))
  )

(defun find-cell-pos (cell-pos quiz-info-list)
"[tesuji]に対応したセル位置が存在するかをチェックする。
存在した場合は、存在したノード番号とセル情報を返す。
"
  (let (node-num p)
    (dolist (quiz-info quiz-info-list)
      (setf node-num (first quiz-info))
      (setf p (second quiz-info))
      (dolist (q p)
        (dolist (r q)
          (when (equal cell-pos (fourth r))
	    ;; (do-fundamental unique-candidate (col 8) (mustbe (3 8) 1))
            (return-from find-cell-pos (values node-num r)) ;; [r] ::= [手筋情報] ;
            )
          ) ;; end dolist
        )   ;; end dolist
      )	    ;; end doist
    (return-from find-cell-pos (values nil nil))
    ) ;; end let
  )

(defun find-row-pos (row quiz-info-list)
"[tesuji]に対応した行位置が存在するかをチェックする。
存在した場合は、存在したノード番号と行情報を返す。('row [number] (('cell ([row] [col])) [number]))"
  (let (node-num p)
    (dolist (quiz-info quiz-info-list)
      (setf node-num (first quiz-info))
      (setf p (second quiz-info))
      (dolist (q p)
        (dolist (r q)
;;        [r] ::= (do-fundamental unique-candidate (row 2) (mustbe 8 3))
          (when (and
		 (equal (first (third r)) 'row)
		 (equal row (third r))
		 )
            (return-from find-row-pos (values node-num r)) ;; [r] ::= [手筋情報] ;

            )
          ) ;; end dolist
        )   ;; end dolist
      )	    ;; end doist
    (return-from find-row-pos (values nil nil))
    ) ;; end let
  )

(defun find-col-pos (col quiz-info-list)
"[tesuji]に対応した列位置が存在するかをチェックする。
存在した場合は、存在したノード番号と列情報を返す。('col [number] (('cell ([row] [col])) [number]))"
  (let (node-num p)
    (dolist (quiz-info quiz-info-list)
      (setf node-num (first quiz-info))
      (setf p (second quiz-info))
      (dolist (q p)
        (dolist (r q)
;;        [r] ::= (do-fundamental unique-candidate (col 8) (mustbe 2 3))
          (when (and
		 (equal (first (third r)) 'col)
		 (equal col (third r))
		 )
            (return-from find-col-pos (values node-num r)) ;; [r] ::= [手筋情報] ;
            )
          ) ;; end dolist
        )   ;; end dolist
      )	    ;; end doist
    (return-from find-col-pos (values nil nil))
    ) ;; end let
  )

;; [quiz-info-list]
;;
;; ((1
;;   (((do-fundamental unique-candidate (col 2) (mustbe (4 2) 3))
;;     (do-fundamental unique-candidate (block 3) (mustbe (4 2) 3)))
;;    ((do-fundamental unique-candidate (col 8) (mustbe (2 8) 3))
;;     (do-fundamental unique-candidate (row 2) (mustbe (2 8) 3))
;;     (do-fundamental unique-candidate (block 2) (mustbe (2 8) 3)))
;;    ((do-fundamental unique-candidate (col 8) (mustbe (3 8) 1))
;;     (do-fundamental unique-candidate (block 5) (mustbe (3 8) 1)))))
;;  (2) (3) (4) (5) (6) (7) (8))
(defun find-block-pos (block-form quiz-info-list)
"[tesuji]に対応したブロック位置が存在するかをチェックする。
存在した場合は、存在したノード番号とブロック情報を返す。('block [number] (('cell ([row] [col])) [number]))"
  (let (node-num p)
    (dolist (quiz-info quiz-info-list)
      (setf node-num (first quiz-info))
      (setf p (second quiz-info))
      (dolist (q p)
        (dolist (r q)
;;        [r] ::= (do-fundamental unique-candidate (block 3) (mustbe (4 2) 3))
          (when (and
		 (equal (first (third r)) 'block)
		 (equal block-form (third r))
		 )
            (return-from find-block-pos (values node-num r)) ;; [r] ::= [手筋情報] ;
            )
          ) ;; end dolist
        )   ;; end dolist
      )	    ;; end doist
    (return-from find-block-pos (values nil nil))
    ) ;; end let
  )

(defun guess-game (quiz-info-list)
"
[quiz-info-list] ::= ([quiz-info]+) ; 具体的な定義は関数[guess-game]のdescribeを参照。

[quiz-info] sample.
 ([ノード番号]
   (
    ( ;; [成立する手筋情報]-1
     (do-fundamental unique-candidate (col 2) (mustbe 4 3))
     (do-fundamental unique-candidate (block 3) (mustbe (4 2) 3))
    )
    ( ;; [成立する手筋情報]-2
     (do-fundamental unique-candidate (col 8) (mustbe 2 3))
     (do-fundamental unique-candidate (row 2) (mustbe 8 3))
     (do-fundamental unique-candidate (block 2) (mustbe (2 8) 3)))
    ( ;; [成立する手筋情報]-3
     (do-fundamental unique-candidate (col 8) (mustbe 3 1))
     (do-fundamental unique-candidate (block 5) (mustbe (3 8) 1))
    )
   )
 )"
  (let (brd tmp result)

    (if (null quiz-info-list) (return-from guess-game nil))

    (print-repeated-char-string 72 #\-)
    (setf brd (new-board (get-parent-board-from-quiz-info-list quiz-info-list)))
    (setq tmp (color-mode))
    (color-mode 0)
    (print-board brd)
    (color-mode tmp)
    (finish-output)

    (setq result (select-tesuji quiz-info-list))
    (return-from guess-game result)
    ) ;; end let
  ) ;; end guess-game

(defun examin-board (brd &optional (color 'blue) (first-time-help nil))
  (let (answer authorized-colors)
    
    ;; 使用を許す色名のリスト。
    ;; [*parity-colors*]が[*xterm-parity-colors*]の場合は[*xterm-parity-color-list*]から
    ;; [*elimination-color*]と[*conflict-color*]の特殊用途色を除いたリスト中の色名。
    ;;
    ;; [*parity-colors*]が[*ansi-parity-colors*]の場合は[*ansi-parity-color-list*]から
    ;; [*elimination-color*]と[*conflict-color*]の特殊用途色を除いたリスト中の色名。
    (setq authorized-colors
	  (remove-if #'(lambda (x) (member x '(*elimination-color* *conflict-color*) :test #'equal))
		     *user-authorized-color-list*))

    (loop
      (block examin-board-loop
	(when first-time-help ;; [first-time-help]が[t]なら初回実行時のみ解説を表示する。
	  (setq first-time-help nil)
	  (print-repeated-char-string 72 #\-)
	  (print-examin-board-help)
	  ;;(format t "ヘルプの再表示は\"help\"。\"quit\"で終了。~%")
	  (finish-output)
	  ) ;; end when
	(format t "Enter Cell-Expression (\"help\"でセル式説明) : ")
	(finish-output)
	(setq answer (read-multiple-symbol)) ;; 2番目以降のシンボルは関数[(rest-symbol)]から得られる。
	(clear-input)

	(cond
	  ((member answer '(quit q exit) :test #'equal)
	   (return-from examin-board nil)
	   )
	  ((member answer '(help h) :test #'equal)
	   (setq first-time-help t)
	   (return-from examin-board-loop) ;; goto next loop.
	   )
	  ((and ;; cell式の後ろに色指定を行うことが可能。
	    (identity (rest-symbol))
	    (not (member (first (rest-symbol)) authorized-colors :test #'equal))
	    )
	   (warn "使用できる色名は定義済みの~aだけです。~%" authorized-colors)
	   (format t "デフォルト色の blue を使います。~%")
	   (finish-output)
	   (setq color 'blue)
	   )
	  ((and
	    (identity (rest-symbol))
	    (member (first (rest-symbol)) authorized-colors :test #'equal)
	    )
	   (setq color (first (rest-symbol)))
	   )
	  ) ;; end cond

	(print-colored-cells brd answer color)
	(finish-output)
	) ;; end examin-board-loop
      )	  ;; end loop

    )	;; end let
  ) ;; end examin-board

(defun print-examin-board-help ()
  (cond-print
   (format nil "*盤面上のセル、行、列、ブロック、ハウスなどを論理式を使って指定し、彩色して表示します。~%")
   (minimum-explanation))
  (terpri)
  (cond-print (format nil "(row 2 4) と指定すると2行目と4行目全体を彩色して表示します。~%")
	      (or (normal-explanation) (minimum-explanation)))
  (cond-print
   (format nil
	   "(and (row 2 4) (col 3 5)) と指定すると2行目、4行目と3列目、5列目の交点のセルを彩色して表示します。~%")
   (or (normal-explanation) (minimum-explanation)))
  (cond-print
   (format nil "(or (row 2 4) (col 3 5)) と指定すると2行目、4行目と3列目、5列目全体を彩色して表示します。~%")
   (or (normal-explanation) (minimum-explanation)))
  (cond-print
   (format nil "(cell (2 3) (5 6) (8 9))と指定すると2行3列、5行6列、そして8行9列のセルを彩色して表示します。~%")
   (or (normal-explanation) (minimum-explanation)))
  (when (or (normal-explanation) (minimum-explanation))
    (print-repeated-char-string 72 #\-)
    (help-for 'cell-expression)
    ;;(print-repeated-char-string 72 #\-)
    ) ;; end when
  (finish-output)
  ) ;; end print-examin-board-help

(defun print-colored-cells (brd exp color)
"[exp]の条件を満たすセルを[color]色に彩色して盤面を表示する。"
  (print-normal (paint-cells brd (parse-cell-expression-in-user-coordinate exp brd) color))
  )

(defun parse-cell-expression-in-user-coordinate (exp &optional (brd nil))
"左上が1行1列、右下が9行9列の座標系で記述したセル・アドレス論理式を内部形式アドレスに変換して条件を満たすセル・アドレスのリストを返す。返されるセル・アドレスの座標系は内部形式(左上が0行0列、右下が8行8列)。
[11]> (setq brd (new-board (pm sample-board-5)))
#2A(((1 2 4 5 6) (1 4 6 9) (1 4 6) 7 3 (2 4 6) (2 5 6) (2 8 9) (2 6 9))
    ((2 5 6) 3 7 8 (2 5) (2 6) 1 4 (2 6 9))
    ((2 4 5 6) 8 (4 6) 9 (2 4 5) 1 (2 5 6) 7 (2 3 6))
    ((1 4 7) (1 4 7) 5 6 (2 4) 8 9 (2 3) (1 2 3 7))
    (9 (1 4 6) (1 3 4 6) 5 7 (2 4) (2 6) (2 3) 8)
    ((6 7 8) (6 7) 2 1 9 3 4 5 (6 7))
    (3 2 9 4 1 7 8 6 5)
    ((4 7) 5 8 2 6 9 3 1 (4 7))
    ((1 4 6 7) (1 4 6 7) (1 4 6) 3 8 5 (2 7) (2 9) (2 4 7 9)))
[12]> (print-normal (paint-cells brd
                    (parse-cell-expression-in-user-coordinate '(or (row 2 5) (col 3 5)) brd) 'blue))
#=======================================================================#
# 1 2 . | 1 . . | B . . # . . . | . . B | . 2 . # . 2 . | . 2 . | . 2 . #
# 4 5 6 | 4 . 6 | B . B # . 7 . | . . . | 4 . 6 # . 5 6 | . . . | . . 6 #
# . . . | . . 9 | . . . # . . . | . . . | . . . # . . . | . 8 9 | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . B . | . . B | . . . # . . . | . B . | . B . # B . . | . . . | . B . #
# . B B | . . . | . . . # . . . | . B . | . . B # . . . | B . . | . . B #
# . . . | . . . | B . . # . B . | . . . | . . . # . . . | . . . | . . B #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . B . | . . . # . 2 . | . . . | . 2 3 #
# 4 5 6 | . 8 . | B . B # . 9 . | B B . | . 1 . # . 5 6 | . 7 . | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# 1 . . | 1 . . | . . . # . . . | . B . | . . . # . . . | . 2 3 | 1 2 3 #
# 4 . . | 4 . . | . B . # . 6 . | B . . | . 8 . # . 9 . | . . . | . . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | B . . | B . B # . . . | . . . | . B . # . B . | . B B | . . . #
# . . . | B . B | B . B # . B . | . . . | B . . # . . B | . . . | . . . #
# . . B | . . . | . . . # . . . | B . . | . . . # . . . | . . . | . B . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . B . # . . . | . . . | . . . # . . . | . . . | . . . #
# . . 6 | . . 6 | . . . # . 1 . | . . . | . 3 . # . 4 . | . 5 . | . . 6 #
# 7 8 . | 7 . . | . . . # . . . | . . B | . . . # . . . | . . . | 7 . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | B . . | . . . # . . . | . . . | . . . #
# . 3 . | . 2 . | . . . # . 4 . | . . . | . 7 . # . 8 . | . 6 . | . 5 . #
# . . . | . . . | . . B # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# 4 . . | . 5 . | . . . # . 2 . | . . B | . 9 . # . 3 . | . 1 . | 4 . . #
# 7 . . | . . . | . B . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | 1 . . | B . . # . . . | . . . | . . . # . 2 . | . 2 . | . 2 . #
# 4 . 6 | 4 . 6 | B . B # . 3 . | . . . | . 5 . # . . . | . . . | 4 . . #
# 7 . . | 7 . . | . . . # . . . | . B . | . . . # 7 . . | . . 9 | 7 . 9 #
#=======================================================================#

ちなみに「全てのセル」は '(not nil) または '(not) で表せる。
"
  (parse-cell-expression (convert-to-internal-address exp) brd)
  )

(defun print-cell-expression (exp brd &key (color 'blue) (internal t))
  "セル式で指定されたセルを指定された[color]色で彩色して表示する。
キーワード引数[internal]にはセルが内部形式なら[t]、外部形式なら[nil]を指定する。デフォルトは[t]。"
  (cond
    ((identity internal)
     (print-normal (paint-cells brd (parse-cell-expression exp brd) color))
     )
    ((null internal)
     (print-normal (paint-cells brd (parse-cell-expression-in-user-coordinate exp brd) color))
     )
    ) ;; end cond
  ) ;; end print-cell-expression

(defun parse-cell-expression (exp &optional (brd nil))
"parse cell expression : row col cell block house chainで組み立てられた and or not からなる論理式を満たすセルのリストを返す。

[and]   ::= (and [exp]*) ; 
[or]    ::= (or  [exp]*) ;
[not]   ::= (not [exp]*) = (not (or [exp-1] [exp-2]...[exp-n])) ;

[exp]   ::= ({and | or | not} [exp]*) | [cell] | [row] | [col] | [cell] | [block] | [chain] | [house] ;

[row]   ::= (row [i-exp]+) ;
[col]   ::= (col [i-exp]+) ;
[cell]  ::= (cell [exp]+) ;
[block] ::= (block [i-exp]+) ;
[chain] ::= (chain [exp]+) ;
[house] ::= (house [address]) ;
[address] ::= ([integer] [integer]) ;
[candidate]  ::= ({cand|candidate}) | ({cand|candidate} {[i-exp]* | ([i-exp]+)}) ;
[determined] ::= ({det|determined}) | ({det|determined} {[i-exp]* | ([i-exp]+)}) ;
[i-exp] ::= 結果が整数となる式 ;

(parse-cell-expression '(not)) は全てのセル・アドレスを返す。
(parse-cell-expression '(and)) は[nil]を返す。
(parse-cell-expression '(or)) は[nil]を返す。

* [candidate]式は指定された候補数字を含むセル・アドレスを返す。複数の候補数字が指定された場合は全ての候補数字を
含むセル・アドレスを返す。オプショナル引数の[brd]が必要。

(parse-cell-expression '(candidate) brd) は確定値でない全てのセル・アドレスを返す。
(parse-cell-expression '(candidate (1 4)) brd) は候補数字1と4の両方を含むセル・アドレスを返す。
(parse-cell-expression '(or (candidate (1)) (candidate (4))) brd) は候補数字1か4のいずれか、
または両方を含むセル・アドレスを返す。

* [determined]式は指定されたセル・アドレスの内、確定値であるセル・アドレスを返す。 オプショナル引数の[brd]が必要。

(parse-cell-expression '(determined) brd) は全ての確定値のセル・アドレスを返す。
(parse-cell-expression '(determined (3 7)) brd) は確定値が3か7である全てのセル・アドレスを返す。
(parse-cell-expression '(or (determined 3) (detemined 7)) brd) は上の式と同じ意味。

Notice. [s*]は直前の[s]のゼロ回以上の繰り返し、[s+]は直前の[s]の1回以上の繰り返し。
「{A|B}」は「AかB」のどちらか一方。

see ref.
(same-block-cells-for-block [num])
(same-row-cells-for-row [num])
(same-col-cells-for-col [num])
(same-house-cells ([i] [j]))
"
  (let (result tmp)
    (cond
      ;;--------------------------------------------------------------------------
      ((null exp)
       nil
       )
      ;;--------------------------------------------------------------------------
      ((symbolp exp)
       nil
       )
      ;;--------------------------------------------------------------------------
      ((cell-addr-p exp 'internal)
       exp
       )
      ;;--------------------------------------------------------------------------
      ((pure-listp (first exp))
       (cons (parse-cell-expression (first exp) brd) (parse-cell-expression (rest exp) brd))
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'and)
       (intersection (parse-cell-expression (second exp) brd)
		     (mapcan #'(lambda (x) (parse-cell-expression x brd)) (cddr exp)) :test #'equal)
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'or)
       (union (parse-cell-expression (second exp) brd)
	      (mapcan #'(lambda (x) (parse-cell-expression x brd)) (cddr exp)) :test #'equal)
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'not)
       (setq tmp (mapcar #'(lambda (x) (parse-cell-expression x brd)) (cdr exp)))
       (set-difference (all-cells) tmp :test #'equal)
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'row)
       (setq result nil)
       (dolist (p (rest exp) result)
	 (setq result (union (same-row-cells-for-row (eval p)) result :test #'equal))
	 )
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'col)
       (setq result nil)
       (dolist (p (rest exp) result)
	 (setq result (union (same-col-cells-for-col (eval p)) result :test #'equal))
	 )
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'block)
       (setq result nil)
       (dolist (p (rest exp) result)
	 (setq result (union (same-block-cells-for-block (eval p)) result :test #'equal))
	 )
       )
      ;;--------------------------------------------------------------------------
      ((member (first exp) '(cell chain) :test #'equal)
       (mapcar #'(lambda (x) (parse-cell-expression x brd)) (cdr exp))
       )
      ;;--------------------------------------------------------------------------
      ((member (first exp) '(house union))
       (same-house-cells (second exp))
       )
      ;;--------------------------------------------------------------------------
      ((member (first exp) '(candidate cand) :test #'equal)
       (when (null brd)
	 (format t "error at parse-cell-expression: 正しい盤面データが必要です。~%")
	 (return-from parse-cell-expression nil)
	 )
       (cond
	 ((null (rest exp))
	  (set-difference
	   (parse-cell-expression '(not) brd) ;; = 全てのセル・アドレス。
	   (parse-cell-expression '(determined) brd) :test #'equal) ;; = 全ての確定値のセル・アドレス。
	  )
	 (t
	  (find-candidate-addr brd (eval-rest-exp (rest exp)))
	  )
	 ) ;; end cond
       )
      ;;--------------------------------------------------------------------------
      ((member (first exp) '(determined det) :test #'equal)
       (when (null brd)
	 (format t "error at parse-cell-expression: 正しい盤面データが必要です。~%")
	 (return-from parse-cell-expression nil)
	 )
       (cond
	 ((null (rest exp)) ;; ({det|determined})
	  (find-determined-value-addr brd *np-digit*) ;; 全ての確定値が対象。
	  )
	 (t
	  (find-determined-value-addr brd (eval-rest-exp (rest exp)))
	  )
	 ) ;; end cond
       )
      ;;--------------------------------------------------------------------------
      ((pure-listp exp)
       (mapcan #'(lambda (x) (parse-cell-expression x brd)) exp)
       )
      ;;--------------------------------------------------------------------------
      ) ;; end cond
    )	;; end let
  ) ;; end parse-cell-expression

(defun eval-rest-exp (rest-exp)
  "関数[eval-rest-exp]の前段関数。戻り値の検査を行う。本体は[eval-rest-exp]。"
  (let (result error-cand max-cand)
    (setq max-cand (1- *board-size*))
    (setq error-cand nil)
    (setq result (eval-rest-exp-sub rest-exp))
    (dolist (p result)
      (if (not (<= 0 p max-cand))
	  (push p error-cand)
	  ) ;; end if
      ) ;; end dolist
    (when (identity error-cand)
      (error "セル式中の[candidate]または[determined]に指定された内部表現候補数字~aのうち~aが有効範囲\=~a外です。"
	      result (reverse error-cand) (mapcar #'1- *np-digit*))
      ) ;; end when
    (return-from eval-rest-exp result)
    ) ;; end let
  ) ;; end eval-rest-exp

(defun eval-rest-exp-sub (rest-exp)
  "シンプル・リスト形式と、リストのリスト形式の候補数字または候補数字式を計算済みのシンプル・リストに
して返す。

(candidate 1 2 5)             ==> (1 2 5)
(candidate (+ 0 1) 2 5)       ==> (1 2 5)
(candidate (1 2 5))           ==> (1 2 5)
(candidate ((+0 1) 2 (+ 2 3)) ==> (1 2 5)

[determined]でも同じ。引数として、それぞれの[cdr]部分を受け取る。
"
  (cond
    ((integerp (car rest-exp)) ;; ( [num] {[num]|[i-exp]}+ ) = シンプル・リスト。 ex. (1 2 5)
     (mapcar #'eval rest-exp)
     )
    ((and ;; ( [i-exp]{[num]|[i-exp]}+ ) = シンプル・リスト。 ex. ( (+ 0 1) 2 5 )
      (pure-listp (car rest-exp))
      (symbolp (caar rest-exp))
      (fboundp (caar rest-exp))
      )
     (mapcar #'eval rest-exp)
     )
    ((and ;; ( ([num]{[num]|[i-exp]}+) ) = リストの中にシンプル・リスト。ex. ( (1 2 5) )
      (pure-listp (car rest-exp))
      (integerp (caar rest-exp))
      )
     (mapcar #'eval (car rest-exp))
     )
    ((and ;; ( ([i-exp]{[num]|[i-exp]}+) ) = リストの中にシンプル・リスト。 ex. ( ((+ 0 1) 2 5 (* 2 4)) )
      (pure-listp (car rest-exp))
      (pure-listp (caar rest-exp))
      (symbolp (caaar rest-exp))
      (fboundp (caaar rest-exp))
      )
     (mapcar #'eval (car rest-exp))
     )
    ) ;; end cond
  ) ;; end eval-rest-exp-sub

(defun find-candidate-addr (brd cand-list)
  "[cand-list]で指定される候補数字全てを持つセル・アドレスのリストを返す。"
  (let (contents cells)
    (setq cells nil)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
	(setq contents (aref brd i j))
	(if (and (pure-listp contents) (subsetp cand-list contents :test #'equal))
	    (push (list i j) cells)
	    ) ;; end if
	) ;; end dolist
      ) ;; end dolsit
    (return-from find-candidate-addr (reverse cells))
    ) ;; end let
  ) ;; end find-candidate-addr

(defun find-determined-value-addr (brd det-list)
  "[det-list]で指定される確定値を持つセル・アドレスのリストを返す。"
  (let (contents cells)
    (setq cells nil)
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
	(setq contents (aref brd i j))
	(if (and (integerp contents) (member contents det-list :test #'=))
	    (push (list i j) cells)
	    ) ;; end if
	) ;; end dotimes
      ) ;; end dotimes
    (return-from find-determined-value-addr (reverse cells))
    ) ;; end let
  ) ;; end find-determined-value-addr

(defun user-formed-cell-expression-p (exp)
  (cell-expression-p (convert-to-internal-address exp))
  )

(defun cell-expression-p (exp &optional (brd nil))
  (parse-cell-expression exp brd)
  )

(defun equal-mustbe-p (exp-1 exp-2)
  "ふたつの引数[exp-1]と[exp-2]がmustbe形式の等価な式か否かを返す。"
  (cond
    ((and
      (pure-listp exp-1)
      (pure-listp exp-2)
      (= (length exp-1) 3)
      (= (length exp-2) 3)
      (equal (first exp-1) 'mustbe)
      (equal (first exp-2) 'mustbe)
      (equal (second exp-1) (second exp-2))
      )
     (cond
       ((and
	 (integerp (third exp-1))
	 (integerp (third exp-2))
	 )
	(= (third exp-1) (third exp-2))
	)
       ((and
	 (integerp (third exp-1))
	 (pure-listp (third exp-2))
	 (= (length (third exp-2)) 1)
	 )
	(equal (third exp-1) (first (third exp-2)))
	)
       ((and
	 (pure-listp (third exp-1))
	 (integerp (third exp-2))
	 (= (length (third exp-2)) 1)
	 )
	(equal (first (third exp-1)) (third exp-2))
	)
       ((and
	 (pure-listp (third exp-1))
	 (= (length (third exp-1)) 1)
	 (pure-listp (third exp-2))
	 (= (length (third exp-2)) 1)
	 )
	(equal (first (third exp-1)) (first (third exp-2)))
	)
       ) ;; end cond
     )
    (t
     nil
     )
    ) ;; end cond
  ) ;; end equal-mustbe-p

(defun equal-cannotbe-p (exp-1 exp-2)
  "ふたつの引数[exp-1]と[exp-2]がcannotbe形式の等価な式か否かを返す。"
  (cond
    ((and
      (pure-listp exp-1)
      (pure-listp exp-2)
      (= (length exp-1) 3)
      (= (length exp-2) 3)
      (equal (first exp-1) 'cannotbe)
      (equal (first exp-2) 'cannotbe)
      (equal (second exp-1) (second exp-2))
      )
     (cond
       ((and ;; 本来は両方ともリスト。
	 (integerp (third exp-1))
	 (integerp (third exp-2))
	 )
	(= (third exp-1) (third exp-2))
	)
       ((and
	 (integerp (third exp-1))
	 (pure-listp (third exp-2))
	 )
	(equal (third exp-1) (first (third exp-2)))
	)
       ((and
	 (pure-listp (third exp-1))
	 (integerp (third exp-2))
	 )
	(equal (first (third exp-1)) (third exp-2))
	)
       ((and
	 (pure-listp (third exp-1))
	 (pure-listp (third exp-2))
	 )
	(equal (sort (third exp-1) #'<) (sort (third exp-2) #'<))
	)
       ) ;; end cond
     )
    (t
     nil
     )
    ) ;; end cond
  ) ;; end equal-cannotbe-p

(defun equal-cannotbe-or-mustbe-p (exp-1 exp-2)
  (cond
    ((equal (first exp-1) 'cannotbe)
     (equal-cannotbe-p exp-1 exp-2)
     )
    ((equal (first exp-1) 'mustbe)
     (equal-mustbe-p exp-1 exp-2)
     )
    )
  )

(defun convert-to-internal-address (exp)
  "セル・アドレス論理式に含まれるユーザ形式アドレスを内部形式アドレスに変換する。
ユーザが使うアドレスは左上が1行1列で右下が9行9列。
内部形式のアドレスは配列の添字に合わせて左上が0行0列で右下が8行8列。
(convert-to-internal-address '(and (row 2 4) (col 1 3))) ==> (and (row 1 3) (col 0 2))"
  (let (result tmp error-exist)
    (cond
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'and)
       (setq tmp (mapcar #'convert-to-internal-address (cdr exp)))
       (cons 'and tmp)
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'or)
       (setq tmp (mapcar #'convert-to-internal-address (cdr exp)))
       (cons 'or tmp)
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'not)
       (setq tmp (mapcar #'convert-to-internal-address (cdr exp)))
       (cons 'not tmp)
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'row)
       (setq result nil)
       (setq error-exist nil)
       (dolist (p (rest exp))
	 (if (and (numberp p) (<= 0 p (1- (board-size))))
	     (push (1- p) result)
	     (progn
	       (setq error-exist t)
	       (format t "~aは正しい行番号ではありません。~%" p)
	       (finish-output)
	       )
	     ) ;; end if
	 )     ;; end dolist
       (if error-exist
	   nil
	   (cons 'row (reverse result))
	   )
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'col)
       (setq result nil)
       (setq error-exist nil)
       (dolist (p (rest exp))
	 (if (and (numberp p) (<= 0 p (1- (board-size))))
	     (push (1- p) result)
	     (progn
	       (setq error-exist t)
	       (format t "~aは正しい列番号ではありません。~%" p)
	       (finish-output)
	       )
	     ) ;; end if
	 )     ;; end dolist
       (if error-exist
	   nil
	   (cons 'col (reverse result))
	   )
       )
      ;;--------------------------------------------------------------------------
      ((equal (first exp) 'block)
       (setq result nil)
       (setq error-exist nil)
       (dolist (p (rest exp))
	 (if (and (numberp p) (<= 0 p (1- (board-size))))
	     (push (1- p) result)
	     (progn
	       (setq error-exist t)
	       (format t "~aは正しいブロック番号ではありません。~%" p)
	       (finish-output)
	       )
	     ) ;; end if
	 )     ;; end dolist
       (if error-exist
	   nil
	   (cons 'block (reverse result))
	   )
       )
      ;;--------------------------------------------------------------------------
      ((member (first exp) '(cell chain))
       (setq result nil)
       (setq error-exist nil)
       (dolist (p (rest exp))
	 (if (and (pure-listp p) (= (length p) 2))
	     (push (list (1- (first p)) (1- (second p))) result)
	     )
	 (when (not (cell-addr-p p))
	   (setq error-exist t)
	   (format t "~aは正しいセル・アドレスではありません。~%" p)
	   (finish-output)
	   ) ;; end when
	 )   ;; end dolist
       (if error-exist
	   (return-from convert-to-internal-address nil)
	   (cons (first exp) (reverse result))
	   ) ;; end if
       )
      ;;--------------------------------------------------------------------------
      ((member (first exp) '(house union))
       ;;(setq result (same-house-cells (list (1- (first (second exp))) (1- (second (second exp))))))
       (same-house-cells (list (1- (first (second exp))) (1- (second (second exp)))))
       )
      ;;--------------------------------------------------------------------------
      ((member (first exp) '(candidate cand) :test #'equal)
       exp
       )
      ;;--------------------------------------------------------------------------
      ((member (first exp) '(determined det) :test #'equal)
       exp
       )
      ) ;; end cond
    ) ;; end let
  ) ;; end convert-to-internal-address

(defun to-internal-address (exp)
  "外部形式セル・アドレスを内部形式セル・アドレスに変換する。

[mustbe-exp] ::= (mustbe [address] [candidate]) ;
[cannotbe-exp] ::= (cannotbe [address] [candidate-list]) ;
[cell]  ::= (cell [address]+) ;
[chain] ::= (chain [address]+) ;
[house] ::= (house [address]) ;
[candidate-list] ::= ([candidate]+) ;
[candidate] ::= 0..*board-size* ;"
  (let (result key-word)
    (setq result nil)
    (cond
      ;;--------------------------------------------------------------------------
      ((and
	(pure-listp exp)
	(= (length exp) 3)
	(equal (first exp) 'mustbe)
	;;(cell-addr-p (list (1- (first (second exp))) (1- (second (second exp)))))
	(cell-addr-p (to-internal-address-kernel (second exp)) 'internal)
	(or
	 (pure-listp (third exp)) ;; (mustbe (i j) (k+))を許す。
	 (zero-or-positive-integerp (third exp))
	 )
	)
       ;;(list 'mustbe (list (1- (first (second exp))) (1- (second (second exp)))) (third exp))
       (list 'mustbe (to-internal-address-kernel (second exp)) (third exp))
       )
      ;;--------------------------------------------------------------------------
      ((and
	(pure-listp exp)
	(= (length exp) 3)
	(equal (first exp) 'cannotbe)
	;;(cell-addr-p (list (1- (first (second exp))) (1- (second (second exp)))))
	(cell-addr-p (to-internal-address-kernel (second exp)) 'internal)
	(or
	 (pure-listp (third exp))
	 (zero-or-positive-integerp (third exp)) ;; (cannotbe (i j) k)を許す。
	 )
	)
       ;;(list 'cannotbe (list (1- (first (second exp))) (1- (second (second exp)))) (third exp))
       (list 'cannotbe (to-internal-address-kernel (second exp)) (third exp))
       )
      ;;--------------------------------------------------------------------------
      ((and
	(pure-listp exp)
	(member (first exp) '(cell chain) :test #'equal)
	)
       (setq key-word (first exp))
       (setq result nil)
       (dolist (p (rest exp))
	 (if (cell-addr-p p 'internal) ;; 内部形式の正しいセル・アドレスか？
	     (push (to-internal-address-kernel p) result)
	     ) ;; end if
	 ) ;; end dolist
       (cons key-word (reverse result))
       )
      ;;--------------------------------------------------------------------------
      ((and
	(pure-listp exp)
	(member (first exp) '(house union group) :test #'equal)
	)
       (setq key-word (first exp))
       (list key-word (to-internal-address-kernel (second exp)))
       )
      ;;--------------------------------------------------------------------------
      (t
       nil
       )
      ) ;; end cond
    )	;; end let
  ) ;; end to-internal-address

(defun to-internal-address-kernel (ext-cell-addr)
  (list (1- (first ext-cell-addr)) (1- (second ext-cell-addr)))
  )

(defun to-external-address (exp)
"[mustbe-exp]と[cannotbe-exp]内の内部形式セル・アドレスを外部形式セル・アドレスに変換する。
セル・アドレス範囲にエラーがあれば[nil]を返す。

[mustbe-exp] ::= (mustbe [address] [candidate]) ;
[cannotbe-exp] ::= (cannotbe [address] [candidate-list]) ;
[candidate-list] ::= ([candidate]+) ;
[candidate] ::= 0..*board-size* ;"
  (let (result key-word)
    (cond
      ;;--------------------------------------------------------------------------
      ((and
	(pure-listp exp)
	(= (length exp) 3)
	(equal (first exp) 'mustbe)
	;; 外部形式の正しいセル・アドレスか？
	(cell-addr-p (to-external-address-kernel (second exp)) 'external)
	(or
	 (pure-listp (third exp)) ;; (mustbe (i j) (k+))を許す。
	 (zero-or-positive-integerp (third exp))
	 )
	)
       (list 'mustbe (to-external-address-kernel (second exp)) (third exp))
       )
      ;;--------------------------------------------------------------------------
      ((and
	(pure-listp exp)
	(= (length exp) 3)
	(equal (first exp) 'cannotbe)
	;; 外部形式の正しいセル・アドレスか？
	(cell-addr-p (to-external-address-kernel (second exp)) 'external)
	(or
	 (pure-listp (third exp))
	 (zero-or-positive-integerp (third exp)) ;; (cannotbe (i j) k)を許す。
	 )
	)
       (list 'cannotbe (to-external-address-kernel (second exp)) (third exp))
       )
      ;;--------------------------------------------------------------------------
      ((and
	(pure-listp exp)
	(member (first exp) '(cell chain) :test #'equal)
	)
       (setq key-word (first exp))
       (setq result nil)
       (dolist (p (rest exp))
	 (if (cell-addr-p p 'external) ;; 外部形式の正しいセル・アドレスか？
	     (push (to-external-address-kernel p) result)
	     ) ;; end if
	 )     ;; end dolist
       (cons key-word (reverse result))
       )
      ;;--------------------------------------------------------------------------
      ((and
	(pure-listp exp)
	(member (first exp) '(house union group) :test #'equal)
	)
       (setq key-word (first exp))
       (list key-word (to-external-address-kernel (second exp)))
       )
      ;;--------------------------------------------------------------------------
      (t
       nil
       )
      ) ;; end cond
    ) ;; end let
    ) ;; end to-external-address

(defun to-external-address-kernel (int-cell-addr)
  (list (1+ (first int-cell-addr)) (1+ (second int-cell-addr)))
  )

(defun print-select-position-help (&optional (kind nil)) ;; kind = 'block 'row 'col 'cell or nil
  (let (fmt)
    (setf fmt (format nil "~~~d,8T" 16)) ;; 書式指示子を動的に作る。この引数だけで全体を調節できる。
    ;;(format t "~s" fmt) returns "~16,8T"
    (cond-print (concatenate 'string " B)lock" fmt "ブロック番号を入力します。~%")
		(and (or (null kind) (equal kind 'block)) (normal-explanation))) ;; 通常以上で表示。
    (cond-print (concatenate 'string fmt "ブロック番号は左上が\"1\"、右下が\"9\"です。~%")
		(and (or (null kind) (equal kind 'block)) (long-explanation))) ;; 詳細表示の場合に表示する。
    (cond-print (concatenate 'string " R)ow" fmt "行番号を入力します。~%")
		(and (or (null kind) (equal kind 'row)) (normal-explanation))) ;; 通常表示以上の場合に表示。
    (cond-print (concatenate 'string fmt "行番号は一番上が\"1\"、一番下が\"9\"です。~%")
		(and (or (null kind) (equal kind 'row)) (long-explanation))) ;; 詳細表示の場合に表示する。
    (cond-print (concatenate 'string " C)ol" fmt "列番号を入力します。~%")
		(and (or (null kind) (equal kind 'col)) (normal-explanation))) ;; 通常表示以上の場合に表示。
    (cond-print (concatenate 'string fmt "列番号は一番が左\"1\"、一番右が\"9\"です。~%")
		(and (or (null kind) (equal kind 'col)) (long-explanation))) ;; 詳細表示の場合に表示する。
    (cond-print (concatenate 'string " Ce)ll" fmt "セル位置を入力します。~%")
		(and (or (null kind) (equal kind 'cell)) (normal-explanation))) ;; 通常表示以上の場合に表示する。
    (cond-print (concatenate 'string fmt "セル位置は左上が1行1列、右下が9行9列です。~%")
		(and (or (null kind) (equal kind 'cell)) (long-explanation))) ;; 詳細表示の場合に表示する。
    (cond-print (concatenate 'string fmt "i行j列は\"(i j)\"または\"i j\"と入力します。。~%")
		(and (or (null kind) (equal kind 'cell)) (long-explanation))) ;; 詳細表示の場合に表示する。
    (if (long-explanation) (terpri))
    (cond-print (concatenate 'string fmt "入力は\")\"の前まで、または\")\"を除いた単語全体を入力します。~%")
		(long-explanation)) ;; 詳細表示の場合に表示する。
    (cond-print (concatenate 'string fmt "大文字小文字は区別しません。\"b 1\"も\"BLOCK 1\"も同じです~%")
		(long-explanation)) ;; 詳細表示の場合に表示する。
    (cond-print (concatenate 'string fmt "キーワード部分のみの入力だと直後に位置情報部分の入力を求められます。~%")
		(long-explanation)) ;; 詳細表示の場合に表示する。
    (finish-output)
    
    ) ;; end let
  )

(defun select-position (&optional (kind nil)) ;; kind = 'block 'row 'col 'cell or nil
"先行入力を許す形式でブロック、行、列、セル位置の入力を受け付けて結果を返す。
結果は'(block 3), (row 2), (cell (2 3))などの形式。位置を示す数値は左上のセルを0、右下のセルを8とする内部形式。
位置種別(ブロック・行・列・セル)を短縮表記で入力してもフルスペル形式で返す。"
  (let (cell-pos row-pos col-pos blk-pos answer result)

    (setf blk-pos  nil) ;; 念のための初期化。
    (setf row-pos  nil)
    (setf col-pos  nil)
    (setf cell-pos nil)
    (setf result   nil)

    (loop
      (print-select-position-help kind)
      (loop
	(if (identity kind)
	    (format t "~aに関する位置情報を入力して下さい(中止は\"quit\")。: " kind)
	    (format t "位置情報を入力してください(中止は\"quit\")。: ")
	    )
	(finish-output)
	(setq answer (read-multiple-symbol))
	(if (or
	     (null kind)
	     (equal answer kind)
	     (member answer '(quit q exit) :test #'equal)
	     )
	    (return)
	    ) ;; end if
	) ;; end loop

      (cond
	((member answer '(quit q exit)) ;; 'quit 'exitなら中止。
	 (return-from select-position nil)
	 )
	((member answer '(b block) :test #'equal)
	 (cond
	   ((rest-symbol)
	    (setq blk-pos (first (rest-symbol)))
	    (setq result (list 'block blk-pos))
	    )
	   ((null (rest-symbol))
	    (format t "ブロック番号 : ")
	    (finish-output)
	    (setq blk-pos (read))
	    (clear-input)
	    (setq result (list 'block blk-pos))
	    )
	   )
	 )
	((member answer '(r row))
	 (cond
	   ((rest-symbol)
	    (setq row-pos (first (rest-symbol)))
	    (setq result (list 'row row-pos))
	    )
	   ((null (rest-symbol))
	    (format t "行番号 : ")
	    (finish-output)
	    (setq row-pos (read))
	    (clear-input)
	    (setq result (list 'row row-pos))
	    )
	   )
	 )
	((member answer '(c col column))
	 (cond
	   ((rest-symbol)
	    (setq col-pos (first (rest-symbol)))
	    (setq result (list 'col col-pos))
	    )
	   ((null (rest-symbol))
	    (format t "列番号 : ")
	    (finish-output)
	    (setq col-pos (read))
	    (clear-input)
	    (setq result (list 'col col-pos))
	    )
	   )
	 )
	((member answer '(ce cell))
	 (cond
	   ((and
	     (rest-symbol)
	     (pure-listp (first (rest-symbol)))
	     )
	    (setq cell-pos (first (rest-symbol)))
	    (setq result (list 'cell cell-pos ))
	    )
	   ((and
	     (>= (length (rest-symbol)) 2)
	     (numberp (first (rest-symbol)))
	     (numberp (second (rest-symbol)))
	     )
	    (setq cell-pos (list (first (rest-symbol)) (second (rest-symbol))))
	    (setq result (list 'cell cell-pos))
	    )
	   ((null (rest-symbol))
	    (format t "セル位置 : ")
	    (finish-output)
	    (setq cell-pos (read-multiple-symbol))
	    (clear-input)
	    (cond
	      ((pure-listp cell-pos)
	       (setq result (list 'cell (list (first cell-pos) (second cell-pos))))
	       )
	      ((and
		(rest-symbol)
		(numberp cell-pos)
		(numberp (first (rest-symbol)))
		)
	       (setq cell-pos (list cell-pos (first (rest-symbol))))
	       (setq result (list 'cell cell-pos))
	       )
	      )
	    )
	   )
	 )
	)

      (if (member result '(quit q exit)) (throw 'step-around-loop nil))
      (when (and
	     (member answer '(b block r row c col column ce cell))
	     (check-positions-range result)
	     )
	(return) ;; exit loop
	)	 ;; end when
      (format t "~a : 数値の範囲は 1..~d です。正しい範囲の数値を指定して下さい。~%" result (board-size))
      (finish-output)
      ) ;; end loop

    ;; [result] ::= '(block [ブロック番号]) | '(row [行番号]) | '(col [列番号]) | '(cell ([行番号] [列番号])) ;
    (cond
      ((and ;; must be cell.
	(pure-listp (second result))
	(integerp (first (second result)))
	(integerp (second (second result)))
	)
       (setq result (list (first result) (1- (first (second result))) (1- (second (second result)))))
       )
      ((integerp (second result)) ;; '(block [n]) or '(row [n])  or '(col [n])
       (setq result (list (first result) (1- (second result))))
       )
      (t
       (setq result nil)
       )
      ) ;; end cond

    (return-from select-position result)
    ) ;; end let
  ) ;; end select-position

(defun check-positions-range (pos) ;; [pos] ::= '(block [n]) | '(row [n]) | '(col [n]) | '(cell ([n] [m]))
  (if (not (member (first pos) '(block row col cell)))
      (return-from check-positions-range nil)
      ) ;; end if
  (cond
    ((pure-listp (second pos)) ;; must be '(cell ([n] [m]))
     (and
      (<= 1 (first (second pos)) (board-size))
      (<= 1 (second (second pos)) (board-size))
      )
     )
    ((numberp (second pos))
     (<= 1 (second pos) (board-size))
     )
    (t
     nil
     )
    ) ;; end cond
  ) ;; end check-position-range

(defun select-tesuji (quiz-info-list)
  (let (brd select result lst num answer node-num arranged-list solution-info quiz-list
	used-list last-tesuji-num)

    ;; [195]> (function-name-to-tesuji-name-list)
    ;;((do-fundamental . "基本手筋") (do-localization . "ローカライゼーション")
    ;; (do-n-tuples . "n国同盟") (do-n-grid . "nグリッド")
    ;; (do-almost-locked-set . "Almost Locked Set")
    ;; (do-grid-based-locked-set . "Grid Based Almost Locked Set") (do-pattern-overlay-method . "配置確定法")
    ;; (do-advanced-coloring . "Advanced Coloring") (do-nice-loop . "Nice Loop")
    ;; (do-trial-and-error . "試行錯誤法"))
    ;;
    ;; [196]> (setf lst (remove-if #'(lambda (x) (equal (car x) 'do-trial-and-error))
    ;;                             (function-name-to-tesuji-name-list)))
    ;;((do-fundamental . "基本手筋") (do-localization . "ローカライゼーション")
    ;; (do-n-tuples . "n国同盟") (do-n-grid . "nグリッド")
    ;; (do-almost-locked-set . "Almost Locked Set")
    ;; (do-grid-based-locked-set . "Grid Based Almost Locked Set") (do-pattern-overlay-method . "配置確定法")
    ;; (do-advanced-coloring . "Advanced Coloring") (do-nice-loop . "Nice Loop"))

    (setf lst ;; 試行錯誤法[do-trial-and-error]は対象外とする。
	  (remove-if #'(lambda (x) (equal (car x) 'do-trial-and-error))
		     (function-name-to-tesuji-name-list)))
    (setq arranged-list (get-tesuji-list quiz-info-list)) ;; 実際に使用された手筋関数名のリスト。
    (setq brd (new-board (get-parent-board-from-quiz-info-list quiz-info-list)))

    ;;---------------------------------------------------------------------------------
    (loop
      (block select-tesuji-loop
	(setf num -1)
	(setq used-list nil)

	(print-repeated-char-string 72 #\-)
	(finish-output)

	(dolist (p lst) ;; [lst]は試行錯誤法以外の実装済みの手筋関数名と表示関数名のペア・リストのリスト。
	  (cond
	    ((and
	      (identity (show-used-tesuji))
	      (member (car p) arranged-list :test #'equal)
	      )
	     (incf num)
	     (multiple-value-setq (solution-info node-num) (get-solution-info quiz-info-list (car p)))
	     ;; 変数[solution-info]はselect-tesuji内で使っていない。
	     ;; 次の無意味な式は、コンパイラのwarning messageを抑止するためのダミー。
	     (setq solution-info solution-info)

	     (setq quiz-list (get-quiz-list (find-node node-num)))
	     (format t "~8t~2d~8t*~a ~:a~%" num (cdr p) quiz-list) ;; 実際に適用されていた関数名なら"*"を表示。
	     (push num used-list)
	     )
	    (t
	     (format t "~8t~2d~8t ~a~%" (incf num) (cdr p)) ;; 適用されていない関数名なら単に空白文字。
	     ;; 選択できるのは[used-list]に登録されている番号のみ。
	     ;; ※「(push num used-list)」しないことで、番号を選択できないようにしている。
	     ) ;; end if
	    )  ;; end cond
          (finish-output)
          ) ;; end dolist

	(setq last-tesuji-num num)
      
	(format t "~8t~2d~8t 盤面についての情報を表示する。~%" (incf num))
	(push num used-list)
	(setf (get 'menu-num 'show-information) num)
	;;(format t "num=~d, (get 'menu-num 'show-information)=~d~%" num (get 'menu-num 'show-information))

	(format t "~8t~2d~8t セル式の条件にあうセルを彩色して表示する(盤面検討モード)。~%" (incf num))
	(push num used-list)
	(setf (get 'menu-num 'cell-expression) num)
	;;(format t "num=~d, (get 'menu-num 'cell-expression)=~d~%" num (get 'menu-num 'cell-expression))

	(format t "~8t[番号]+\"h\)int\"で該当手筋のヒント。~%")
	(format t "~8t[番号]+\"e\)xplanation\"で該当手筋の解説。~%")
	(format t "~8t[番号]+\"a\)nswer\"で該当手筋に対する解答入力。~%")

	(format t "Select number (\"help\"でコマンドのヘルプ、\"quit\"で中止) : ")
	(finish-output)
	(setf select (read-multiple-symbol)) ;; [select]には入力先頭のシンボルが入る。
	(clear-input)

	(if (member select '(quit q exit bye) :test #'equal) (return-from select-tesuji nil))

	;; 現在の盤面に対するヒント情報を全て復活する。作業用盤面も初期状態に戻す。
	(when (member select '(restore revive) :test #'equal)
	  (reset-hint-info-and-working-board quiz-info-list)
	  (format t "\*現在の盤面に対するヒント情報を全て復活しました。作業用盤面も初期状態に戻しました。~%")
	  (finish-output)
	  (return-from select-tesuji-loop nil) ;; goto next loop.
	  )				       ;; end when

	;; hintコマンドとanswerコマンドのオプションに関するヘルプを表示する。
	(when (member select '(help h \?) :test #'equal)
	  (print-repeated-char-string 72 #\-)
	  (print-hint-help)
	  (print-repeated-char-string 72 #\-)
	  (print-answer-help)
	  (finish-output)
	  (return-from select-tesuji-loop nil)
	  ) ;; end when

	;; 空行も含めて期待しない入力なら再入力へ。
	(cond
	  ((not (integerp select)) ;; 空行(=[nil])も含めて番号でなければ再入力へ。
	   (format t "手筋選択: \(0...~d\)のいずれかの数字を入力して下さい。~%" num)
	   (return-from select-tesuji-loop nil)
	   )
	  ((not
	    (and
	     (integerp select)
	     (<= 0 select num)
	     ) ;; end and
	    )  ;; end not
	   (format t "手筋選択: \(0...~d\)のいずれかの数字を入力して下さい。~%" num)
	   (finish-output)
	   (return-from select-tesuji-loop nil) ;; goto next loop.
	   )
	  ((and ;; 使用されていない手筋には解答できない。ヒントと該当手筋解説は許す。
	    (integerp select)
	    (identity (rest-symbol))
	    (member (first (rest-symbol)) '(answer ans a) :test #'equal)
	    (not (member select used-list :test #'equal))
	    )
	   (format t "使用されていない手筋(~a)に解答することは出来ません。~%"
		   (cdr (nth select (sort-as (function-name-to-tesuji-name-list) lst))))
	   (finish-output)
	   (return-from select-tesuji-loop nil)
	   )
	  ) ;; end cond

	(setq result nil)
	(cond
	  ((and ;; 盤面に関する情報を表示。
	    (integerp select)
	    (= select (get 'menu-num 'show-information))
	    )
	   (show-information quiz-info-list (get 'menu-num 'show-information))
	   (return-from select-tesuji-loop nil) ;; goto next loop.
	   )
	  ((and ;; セル式による盤面検討モード。
	    (integerp select)
	    (= select (get 'menu-num 'cell-expression))
	    )
	   (examin-board brd 'blue nil) ;; 第3引数が[t]なら初回のみ解説を表示する。
	   )
	  ((and ;; [番号]のみ＝[番号]+"answer"として扱う。
	    (integerp select)
	    ;;(<= 0 select last-tesuji-num)
	    (member select used-list :test #'equal)
	    (null (rest-symbol))
	    )
	   (setq result
		 (answer-for (nth select (sort-as (function-name-to-tesuji-name-list) lst)) quiz-info-list))
	   )
	  ((and ;; [番号]+"hint"+something
	    (integerp select)
	    (<= 0 select last-tesuji-num)
	    ;;(member select used-list :test #'equal)
	    (identity (rest-symbol))
	    (member (first (rest-symbol)) '(hint h) :test #'equal)
	    )
	   (hint-for (nth select (sort-as (function-name-to-tesuji-name-list) lst)) quiz-info-list)
	   (return-from select-tesuji-loop nil) ;; goto next loop.
	   )
	  ((and ;; [番号]+"explanation"+something
	    (integerp select)
	    (<= 0 select last-tesuji-num)
	    ;;(member select used-list :test #'equal)
	    (identity (rest-symbol))
	    (member (first (rest-symbol)) '(explanation ex e) :test #'equal)
	    )
	   (help-for (car (nth select (sort-as (help-name-to-function-name-list) lst))))
	   (return-from select-tesuji-loop nil) ;; goto next loop.
	   )
	  ((and ;; [番号]+"answer"+something
	    (integerp select)
	    ;;(<= 0 select last-tesuji-num)
	    (member select used-list :test #'equal)
	    (identity (rest-symbol))
	    (member (first (rest-symbol)) '(answer ans a) :test #'equal)
	    )
	   (setq result
		 (answer-for (nth select (sort-as (function-name-to-tesuji-name-list) lst)) quiz-info-list))
	   )
	  )				   ;; end cond
	)				   ;; end block
      )					   ;; end loop
    (setf answer (car (nth select lst))) ;; answer has function-name.
    (debug-write "select-tesuji-2" (format nil "answer=~a~%" answer))

    (return-from select-tesuji result)
    ) ;; end let
  ) ;; end select-tesuji

(defun flatten-quiz-info-list (quiz-info-list)
  "[quiz-info-list]のデータ構造を平坦化する。

[quiz-info-list] Version 2.0 (2024-02-25)
[手筋情報]        ::= ([手筋関数名] [成立理由] [位置条件] [位置リスト])
[手筋関数名]      ::= [手筋関数名シンボル] ;
[成立理由]        ::= [文字列] | [シンボル] ;
[位置条件]        ::= ('and [位置条件]+) | ('or [位置条件]+) |
                      ('not [位置条件]+) | [位置条件要素] ;
[位置条件要素]    ::= [cell] | [row] | [col] | [block] | [house] | [chain] | [group] ;
[cell]           ::= ([行番号] [列番号]) ;
[row]            ::= ('row [行番号]) ;
[col]            ::= ('col [列番号]) ;
[block]          ::= ('block [ブロック番号]) ;
[house]          ::= ('house [cell]) ; [cell]を含むハウス。
[chain]          ::= ('chain [cell]+) ;
[削除/確定情報]   ::= (({'mustbe | 'cannotbe} (row col) {[candidate] | ([candidate]+))) ;
[位置リスト]      ::= ([削除/確定情報]+) ;
[quiz-info-list] ::= ([quiz-info]+) ;
[quiz-info]      ::= ([ノード番号] ( ([手筋情報]+) )* ) ;

([ノード番号]
   (
    ( ;; [成立する手筋情報]-1
     (do-fundamental unique-candidate (col 2) ((mustbe (4 2) 3)))
     (do-fundamental unique-candidate (block 3) ((mustbe (4 2) 3)))
    )
    ( ;; [成立する手筋情報]-2
     (do-fundamental unique-candidate (col 8) ((mustbe (2 8) 3)))
     (do-fundamental unique-candidate (row 2) ((mustbe (2 8) 3)))
     (do-fundamental unique-candidate (block 2) ((mustbe (2 8) 3))))
    ( ;; [成立する手筋情報]-3
     (do-fundamental unique-candidate (col 8) ((mustbe (3 8) 1)))
     (do-fundamental unique-candidate (block 5) ((mustbe (3 8) 1)))
    )
   )
 )

を次のように変形する。

 ([ノード番号]
     (do-fundamental unique-candidate (col 2) ((mustbe (4 2) 3)))
     (do-fundamental unique-candidate (block 3) ((mustbe (4 2) 3)))
     (do-fundamental unique-candidate (col 8) ((mustbe (2 8) 3)))
     (do-fundamental unique-candidate (row 2) ((mustbe (2 8) 3)))
     (do-fundamental unique-candidate (block 2) ((mustbe (2 8) 3)))
     (do-fundamental unique-candidate (col 8) ((mustbe (3 8) 1)))
     (do-fundamental unique-candidate (block 5) ((mustbe (3 8) 1)))
 )

したがって[quiz-info-list]を与えると、上記形式の平坦化されたリストのリストが返る。"
  (let (result node-num tmp)
    ;;(format t "quiz-info-list=~a~%" quiz-info-list)
    (setf result nil)
    (dolist (p quiz-info-list)
      (setf tmp nil)
      (setf node-num (pop p))
      (dolist (q p)
        (dolist (r q)
          (dolist (s r)
            (push s tmp)
            ) ;; end dolist
          )   ;; end dolist
        )     ;; end dolist
      (if (null p)
          (push (list node-num) result)
          (push (push node-num tmp) result)
          ) ;; end if
      )	    ;; end dolist
    (return-from flatten-quiz-info-list (reverse result))
    ) ;; end let
  ) ;; end flatten-quiz-info-list

(defun flatten-quiz-info (quiz-info)
  "[game-node]に記録されている[quiz-info]情報を「平坦」にする。

[quiz-info] ::= 
(
 (
  ( ;; [成立する手筋情報]-1
   (do-fundamental unique-candidate (row 3) (mustbe (3 7) 3))
   )
  ( ;; [成立する手筋情報]-2
   (do-fundamental unique-candidate (col 8) (mustbe (2 8) 3))
   (do-fundamental unique-candidate (row 2) (mustbe (2 8) 3))
   (do-fundamental unique-candidate (block 2) (mustbe (2 8) 3))
   )
  ( ;; [成立する手筋情報]-3
   (do-fundamental unique-candidate (col 8) (mustbe (3 8) 1))
   (do-fundamental unique-candidate (block 5) (mustbe (3 8) 1))
   )
  )
 )

結果として以下の例のような手筋情報のリストが返る。
(
 (do-fundamental unique-candidate (row 3) (mustbe (3 7) 3))
 (do-fundamental unique-candidate (col 8) (mustbe (2 8) 3))
 (do-fundamental unique-candidate (row 2) (mustbe (2 8) 3))
 (do-fundamental unique-candidate (block 2) (mustbe (2 8) 3))
 (do-fundamental unique-candidate (col 8) (mustbe (3 8) 1))
 (do-fundamental unique-candidate (block 5) (mustbe (3 8) 1))
)

[quiz-info]は(game-node-quiz-info [node])から得られる。
"
  (let (result)
    (setq result nil)
    (dolist (p (first quiz-info))
      (dolist (q p)
	(push q result)
	) ;; end dolist
      ) ;; end dolist
    (return-from flatten-quiz-info (reverse result))
    ) ;; end let
  ) ;; end flatten-quiz-info

(defun flatted-quiz-info (node)
  (flatten-quiz-info (game-node-quiz-info node))
  )

(defun set-quiz-list (node new-list)
  "(game-node-quiz-list [node])に記録されている未使用手筋解法情報番号のリストを[new-list]に変更する。"
  (cond
    ;;((member (game-node-prev-methods node) *multi-position-function* :test #'equal)
    ((multi-position-function-p (game-node-prev-methods node))
     (setf (game-node-grouped-quiz-list node) new-list)
     )
    (t
     (setf (game-node-quiz-list node) new-list)
     )
    ) ;; end cond
  ) ;; end set-quiz-list

(defun get-quiz-list (node)
  "未使用手筋解法情報番号のリストを返す。"
  (cond
    ;;((member (game-node-prev-methods node) *multi-position-function* :test #'equal)
    ((multi-position-function-p (game-node-prev-methods node))
     (game-node-grouped-quiz-list node)
     )
    (t
     (game-node-quiz-list node)
     )
    ) ;; end cond
  )

(defun get-solution-info (quiz-info-list function-name)
"[quiz-info-list]内で手筋関数名[function-name]が含まれるリストの情報とノード番号を返す。
[quiz-info-list]は (get-quiz-info-list [node]) で得られるリスト。

[solution-info] ::= ([solution-info-element]+) ;
[solution-info-element] ::= ([function-name] [explanation] [position-info] [decision-or-del-info]) ;
[function-name] ::= 手筋関数名 ;
[explanation] ::= 適用手筋に関する説明 ;;
[position-info] ::= 候補を削除・確定するために必要な位置情報 ;
[decision-or-del-info] ::= 候補を削除・確定するための具体的情報 ;

[21]> (get-solution-info quiz-info-list 'do-fundamental)
((do-fundamental unique-candidate (block 5) (mustbe (3 8) 1))
 (do-fundamental unique-candidate (col 8) (mustbe (3 8) 1))
 (do-fundamental unique-candidate (block 2) (mustbe (2 8) 3))
 (do-fundamental unique-candidate (row 2) (mustbe (2 8) 3))
 (do-fundamental unique-candidate (col 8) (mustbe (2 8) 3))
 (do-fundamental unique-candidate (row 3) (mustbe (3 7) 3))) ;
1 ;; 第2の値＝ノード番号

see also (describe 'flatten-quiz-info-list).
"
  (let (flatted-list)
    (setq flatted-list (flatten-quiz-info-list quiz-info-list))
    (dolist (p flatted-list)
      (if (equal (first (second p)) function-name)
	  (return-from get-solution-info (values (rest p) (first p)))
	  ) ;; end if
      ) ;; end dolist
    ) ;; end let
  ) ;; get-solution-info

(defun get-solution-info-from-quiz-info (quiz-info)
  "ノードに記録されている[quiz-info]から直接[solution-info]形式に変換する関数。

[quiz-info] ::= (game-node-quiz-info [node]) ;

[47]> (setq quiz-info (game-node-quiz-info (find-node 1)))
((((do-fundamental \"行内で唯一の候補数字\" (row 3) (mustbe (3 7) 3)))
  ((do-fundamental \"列内で唯一の候補数字\" (col 8) (mustbe (2 8) 3))
   (do-fundamental \"行内で唯一の候補数字\" (row 2) (mustbe (2 8) 3))
   (do-fundamental \"ブロック内で唯一の候補数字\" (block 2) (mustbe (2 8) 3)))
  ((do-fundamental \"列内で唯一の候補数字\" (col 8) (mustbe (3 8) 1))
   (do-fundamental \"ブロック内で唯一の候補数字\" (block 5) (mustbe (3 8) 1)))))

[48] (get-solution-info-from-quiz-info quiz-info)
((do-fundamental \"ブロック内で唯一の候補数字\" (block 6) (mustbe (3 8) 1))
 (do-fundamental \"列内で唯一の候補数字\" (col 8) (mustbe (3 8) 1))
 (do-fundamental \"ブロック内で唯一の候補数字\" (block 2) (mustbe (2 8) 3))
 (do-fundamental \"行内で唯一の候補数字\" (row 2) (mustbe (2 8) 3))
 (do-fundamental \"列内で唯一の候補数字\" (col 8) (mustbe (2 8) 3))
 (do-fundamental \"行内で唯一の候補数字\" (row 3) (mustbe (3 7) 3)))
"
  (let (result)
    (setq result nil)
    (dolist (p (first quiz-info)) ;; [p]は同じ削除・確定情報を持つグループ。
      (dolist (q p)
	(push q result)
	)
      ) ;; end dolist
    (setq result (reverse result))
    (return-from get-solution-info-from-quiz-info result)
    ) ;; end let
  ) ;; end get-solution-info-from-quiz-info

(defun reduce-solution-info (solution-info)
  "削除・確定結果が同じ解法情報をひとつにまとめる。

[solution-info] ::= (get-solution-info quiz-info-list function-name) ;

[232]> solution-info
((do-fundamental \"ブロック内で唯一の候補数字\" (block 6) (mustbe (3 8) 1))
 (do-fundamental \"列内で唯一の候補数字\" (col 8) (mustbe (3 8) 1))
 (do-fundamental \"ブロック内で唯一の候補数字\" (block 2) (mustbe (2 8) 3))
 (do-fundamental \"行内で唯一の候補数字\" (row 2) (mustbe (2 8) 3))
 (do-fundamental \"列内で唯一の候補数字\" (col 8) (mustbe (2 8) 3))
 (do-fundamental \"行内で唯一の候補数字\" (row 3) (mustbe (3 7) 3)))
[233]> (reduce-solution-info solution-info)
((do-fundamental (\"ブロック内で唯一の候補数字\" \"列内で唯一の候補数字\")
  (or (block 6) (col 8)) (mustbe (3 8) 1))
 (do-fundamental \"行内で唯一の候補数字\" (row 3) (mustbe (3 7) 3))
 (do-fundamental
  (\"ブロック内で唯一の候補数字\" \"行内で唯一の候補数字\" \"列内で唯一の候補数字\")
  (or (block 2) (row 2) (col 8)) (mustbe (2 8) 3)))"
  (let (cannotbe-list mustbe-list condensed-cannotbe-list condensed-mustbe-list
	result top i condensed-list target-list)

    (multiple-value-setq (cannotbe-list mustbe-list) (sort-solution-info solution-info))

    (dolist (list-kind (list 'mustbe 'cannotbe))
      (cond ;; [mustbe-list]と[cannotbe-list]
	((equal list-kind 'mustbe)
	 (setq target-list mustbe-list)
	 )
	((equal list-kind 'cannotbe)
	 (setq target-list cannotbe-list)
	 )
	) ;; end cond
      (setq result nil)
      (loop
	(if (null target-list) (return)) ;; exit loop.
	(setq top (first target-list))
	(setq target-list (rest target-list))
	(setq i 0)
	(loop ;; 先頭の要素と[condense]出来るものをcondenseして、condense出来た要素はリストから取り除く。
	      (if (>= i (length target-list)) (return)) ;; インデックスが末尾まで到達していたら脱出。
	      (setq condensed-list (condense top (nth i target-list)))
	      (cond
		((identity condensed-list)
		 (setq top condensed-list)
		 (setf target-list (remove (nth i target-list) target-list :count 1 :from-end nil))
		 )
		((null condensed-list)
		 (incf i)
		 )
		) ;; end cond
	      )   ;; end loop
	(cond
	  ((not (symbolp (first (third top)))) ;; 位置情報部分が ( [位置情報]+ ) 形式。
	   (push (list (first top) (second top) (cons 'or (third top)) (fourth top)) result)
	   )
	  (t ;; [mustbe-list]または[cannotbe-list]内で他の要素とcondense出来なかった要素。
	   (push top result)
	   )
	  ) ;; end cond
	) ;; end loop
      (cond
	((eq list-kind 'mustbe)
	 (setq condensed-mustbe-list result)
	 )
	((eq list-kind 'cannotbe)
	 (setq condensed-cannotbe-list result)
	 )
	)
      ) ;; end dolist

    (return-from reduce-solution-info (append condensed-mustbe-list condensed-cannotbe-list))
    ) ;; end let
  ) ;; end reduce-solution-info

(defun condense (solution-info-1 solution-info-2)
  "\"condense\"出来たらcondense結果を返し、\"condense\"出来なかったら[nil]を返す。"
  (let (result ss-1 ss-2 ts-1 ts-2)
    (setq result nil)
    (cond
      ((or
	(null solution-info-1)
	(null solution-info-2)
	)
       (setq result nil)
       )
      ((and
	(eq (first (fourth solution-info-1)) 'mustbe)
	(eq (first (fourth solution-info-2)) 'mustbe)
	(equal (fourth solution-info-1) (fourth solution-info-2)) ;; (mustbe (i j) k) 部分が等しい。
	)
       (setq ss-1 (second solution-info-1))
       (setq ss-2 (second solution-info-2))
       (setq ts-1 (third solution-info-1))
       (setq ts-2 (third solution-info-2))
       (setq result
	     (list (first solution-info-1) ;; 手筋関数名。
		   (cond		   ;; 手筋説明。
		     ((and
		       (stringp ss-1)
		       (stringp ss-2)
		       )
		      (list ss-1 ss-2)
		      )
		     ((and
		       (stringp ss-1)
		       (listp ss-2)
		       )
		      (append (list ss-1) ss-2)
		      )
		     ((and
		       (listp ss-1)
		       (stringp ss-2)
		       )
		      (append ss-1 (list ss-2))
		      )
		     ((and
		       (listp ss-1)
		       (listp ss-2)
		       )
		      (append ss-1 ss-2)
		      )
		     ) ;; end cond
		   (cond ;; 手筋位置条件。
		     ((and
		       (symbolp (first ts-1))
		       (symbolp (first ts-2))
		       )
		      (list ts-1 ts-2)
		      )
		     ((and
		       (symbolp (first ts-1))
		       (listp (first ts-2))
		       )
		      (append (list ts-1) ts-2)
		      )
		     ((and
		       (listp (first ts-1))
		       (symbolp (first ts-2))
		       )
		      (append ts-1 (list ts-2))
		      )
		     ((and
		       (listp (first ts-1))
		       (listp (first ts-2))
		       )
		      (append ts-1 ts-2)
		      )
		     )
		   (fourth solution-info-1)) ;; 削除・確定情報。
	     )
       )
      ((and
	(eq (first (fourth solution-info-1)) 'cannotbe)
	(eq (first (fourth solution-info-2)) 'cannotbe)
	(equal (second (fourth solution-info-1)) (second (fourth solution-info-2)))
	)
       (setq ss-1 (second solution-info-1))
       (setq ss-2 (second solution-info-2))
       (setq result
	     (list (first solution-info-1)
		   (cond ;; 手筋説明。
		     ((and
		       (stringp ss-1)
		       (stringp ss-2)
		       )
		      (list ss-1 ss-2)
		      )
		     ((and
		       (stringp ss-1)
		       (listp ss-2)
		       )
		      (append (list ss-1) ss-2)
		      )
		     ((and
		       (listp ss-1)
		       (stringp ss-2)
		       )
		      (append ss-1 (list ss-2))
		      )
		     ((and
		       (listp ss-1)
		       (listp ss-2)
		       )
		      (append ss-1 ss-2)
		      )
		     )
		   (cond ;; 手筋位置条件。
		     ((and
		       (symbolp (first ts-1))
		       (symbolp (first ts-2))
		       )
		      (list ts-1 ts-2)
		      )
		     ((and
		       (symbolp (first ts-1))
		       (listp (first ts-2))
		       )
		      (append (list ts-1) ts-2)
		      )
		     ((and
		       (listp (first ts-1))
		       (symbolp (first ts-2))
		       )
		      (append ts-1 (list ts-2))
		      )
		     ((and
		       (listp (first ts-1))
		       (listp (first ts-2))
		       )
		      (append ts-1 ts-2)
		      )
		     )
		   (list 'cannotbe (second (fourth solution-info-1))
			 (sort (union (third (fourth solution-info-1)) (third (fourth solution-info-2))) #'<))
		   )
	     )
       )
      (t
       (setq result nil)
       )
      ) ;; end cond
    (return-from condense result)
    )	      ;; end let
  ) ;; end condense

(defun sort-solution-info (solution-info)
  (let (cannotbe-list mustbe-list new-cannotbe-list new-mustbe-list)
    (setq cannotbe-list nil)
    (setq mustbe-list nil)
    (dolist (p solution-info) ;; cannotbeとmustbeで分離。
      (cond ;; 削除・確定情報を複数持つ場合は対象外。
	((eq (first (first (fourth p))) 'cannotbe)
	  (push p cannotbe-list)
	  )
	((eq (first (first (fourth p))) 'mustbe)
	 (push p mustbe-list)
	 )
	) ;; end cond
      ) ;; end dolist
    (setq new-cannotbe-list
	  (sort cannotbe-list
		#'(lambda (x y) (cell-order-p (second (first (fourth x))) (second (first (fourth y)))))))
    (setq new-mustbe-list
	  (sort mustbe-list
		#'(lambda (x y) (cell-order-p (second (first (fourth x))) (second (first (fourth y)))))))
    (return-from sort-solution-info (values new-cannotbe-list new-mustbe-list))
    ) ;; end let
  ) ;; end sort-solution-info

(defun select-cell-pos (quiz-info-list)
  "ユーザが関数[select-position]によって入力したセル位置が[quiz-info-list]に含まれているか調べる。
存在した場合は、存在するノード番号とセル情報を返す。
セル情報の形式は (do-fundamental unique-candidate (col 8) (mustbe (3 8) 1))"
  (let (node-num cell cell-info)

    (setq cell (select-position 'cell))
    (if (null cell) (throw 'step-around-loop nil))

    (multiple-value-setq (node-num cell-info) (find-cell-pos cell quiz-info-list))
    ;;
    (return-from select-cell-pos (values node-num cell-info))
    ) ;; end let
  )

(defun select-row-pos (quiz-info-list)
  "ユーザが関数[select-position]によって入力した行番号が[quiz-info-list]に含まれているか調べる。
存在した場合は、存在するノード番号と行情報を返す。
行情報の形式は (do-fundamental unique-candidate (row 2) (mustbe (2 8) 3))"
  (let (row-info row node-num)

    (setq row (select-position 'row))
    (if (null row) (throw 'step-around-loop nil))

    (multiple-value-setq (node-num row-info) (find-row-pos row quiz-info-list))
    ;;
    (return-from select-row-pos (values node-num row-info))
    )
  )

(defun select-col-pos (quiz-info-list)
  "ユーザが関数[select-position]によって入力した列番号が[quiz-info-list]に含まれているか調べる。
存在した場合は、存在するノード番号と列情報を返す。
列情報の形式は (do-fundamental unique-candidate (col 8) (mustbe (3 8) 1))"
  (let (col-info col node-num)

    (setq col (select-position 'col))
    (if (null col) (throw 'step-around-loop nil))
    (multiple-value-setq (node-num col-info) (find-col-pos col quiz-info-list))

    (return-from select-col-pos (values node-num col-info))
    )
  )

(defun select-block-pos (quiz-info-list)
  "ユーザが関数[select-position]によって入力したブロック番号が[quiz-info-list]に含まれているか調べる。
存在した場合は、存在するノード番号とブロック情報を返す。
ブロック情報の形式は (do-fundamental unique-candidate (block 5) (mustbe (3 8) 1))"
  (let (block-form block-info node-num)

    (setq block-form (select-position 'block))
    (if (null block-form) (throw 'step-around-loop nil))
    (multiple-value-setq (node-num block-info) (find-block-pos block-form quiz-info-list))

    (return-from select-block-pos (values node-num block-info))
    ) ;; end let
  )

(defun check-the-answer (single-quiz-info figure num cell-pos cand-ans-patn cell-ans)
  ;; [single-quiz-info] ::= (do-fundamental unique-candidate (block 5) (mustbe (3 8) 1))
  (and
   (equal figure (first (third single-quiz-info)))
   (equal num (second (third single-quiz-info)))
   (equal cell-pos (second (fourth single-quiz-info)))
   (equal cand-ans-patn (first (fourth single-quiz-info)))
   (equal cell-ans (third (fourth single-quiz-info)))
   )
  )

(defun hint-for (function-name-pair quiz-info-list)
  "試行錯誤法以外の手筋関数名と表示手筋名のペア・リストの手筋関数名に対するヒントを表示する。
[function-name-pair] ::= ([手筋関数名] . [手筋表示名]) ;"
  (let (brd node-num target-node function-name solution-info quiz-number-list quiz-number)

    ;; [初期設定]-----------------------------------------------------------------------
    (setq function-name (car function-name-pair))
    (multiple-value-setq (solution-info node-num) (get-solution-info quiz-info-list function-name))
    (debug-write "hint-for-1" (format nil "solution-info=~a~%" solution-info))
    (setq target-node (find-node node-num))
    (setq brd (game-node-present-board (parent-node target-node)))
    (setq quiz-number-list (get-quiz-list target-node))
    (debug-write "hint-for-3" (format nil "quiz-number-list=~a~%" quiz-number-list))
    ;;---------------------------------------------------------------------------------

    ;; [入力に応じた処理]---------------------------------------------------------------
    (cond
      ((pure-listp quiz-number-list)
       (cond
	 ((= (length (rest-symbol)) 1) ;; "hint" only.
	  (setq quiz-number (pop quiz-number-list))
	  )
	 ((and ;; hint {restore | revive}
	   (= (length (rest-symbol)) 2)
	   (member (second (rest-symbol)) '(restore revive) :test #'equal)
	   )
	  (setq quiz-number-list (game-node-quiz-list-backup target-node))
	  (setq quiz-number nil)
	  )
	 ((and ;; hint {save | keep}
	   (= (length (rest-symbol)) 2)
	   (member (second (rest-symbol)) '(save keep) :test #'equal)
	   )
	  (setq quiz-number (first quiz-number-list))
	  )
	 ((and ;; hint {kill | delete | del}
	   (= (length (rest-symbol)) 2)
	   (member (second (rest-symbol)) '(kill delete del) :test #'equal)
	   )
	  (setq quiz-number (pop quiz-number-list))
	  )
	 ((and ;; hint [num] ;; 「消費済み」の番号を選ぶ場合は restore してから。
	   (= (length (rest-symbol)) 2)
	   (zero-or-positive-integerp (second (rest-symbol)))
	   (member (second (rest-symbol)) quiz-number-list :test #'=)
	   )
	  (setq quiz-number (second (rest-symbol)))
	  (setq quiz-number-list (remove quiz-number quiz-number-list :test #'=))
	  )
	 ((and ;; hint [num] {save | keep}
	   (= (length (rest-symbol)) 3)
	   (zero-or-positive-integerp (second (rest-symbol)))
	   (member (second (rest-symbol)) quiz-number-list :test #'=)
	   (member (third  (rest-symbol)) '(save keep) :test #'equal)
	   )
	  (setq quiz-number (second (rest-symbol)))
	  )
	 ((and ;; hint [num] {kill | delete | del}
	   (= (length (rest-symbol)) 3)
	   (zero-or-positive-integerp (second (rest-symbol)))
	   (member (second (rest-symbol)) quiz-number-list :test #'=)
	   (member (third  (rest-symbol)) '(kill delete del) :test #'equal)
	   )
	  (setq quiz-number (second (rest-symbol)))
	  (setq quiz-number-list (remove quiz-number quiz-number-list :test #'=))
	  )
	 ) ;; end cond
       )
      ((null quiz-number-list)
       (format t "この手筋に対するヒントはこれ以上ありません。~%")
       (return-from hint-for t)
       )
      )	;; end cond
    ;;---------------------------------------------------------------------------------

    (set-quiz-list target-node quiz-number-list) ;; 消費したリストに更新。

    (when (numberp quiz-number)
      ;;(debug-write "hint-for-4"
      ;;	   (format nil "quiz-number=~a, solution-info=~s~%" cell-expression solution-info))
      ;; [solution-info] ::=
      ;; ((do-fundamental unique-candidate (block 5) (mustbe (3 8) 1))
      ;;  (do-fundamental unique-candidate (col 8) (mustbe (3 8) 1))
      ;;  (do-fundamental unique-candidate (block 2) (mustbe (2 8) 3))
      ;;  (do-fundamental unique-candidate (row 2) (mustbe (2 8) 3))
      ;;  (do-fundamental unique-candidate (col 8) (mustbe (2 8) 3))
      ;;  (do-fundamental unique-candidate (row 3) (mustbe (3 7) 3)))
      (print-hint-info brd quiz-number function-name solution-info)
      ) ;; end when
    )	;; end let
  ) ;; end hint-for

(defun print-hint-help ()
  (format t "[番号]+\"h)int\" {restore|revive} : [番号]に対する問題番号を全回復する。~%")
  (format t "[番号]+\"h)int\" {save|keep} : [番号]の現在の先頭問題を削除せずヒントを表示する。~%")
  (format t "[番号]+\"h)int\" {kill|delete|del} : [番号]の現在の先頭問題を削除する。~%")
  (format t "[番号]+\"h)int\" [num] : [番号]の問題中の[num]番のヒントを表示して削除する。~%")
  (format t "~15t表示されていない(削除された)問題はrestoreするまで表示できない。~%")
  (format t "[番号]+\"h)int\" [num] {save|keep} : [番号]の問題中の[num]番を削除せずにヒントを表示する。~%")
  (format t "[番号]+\"h)int\" [num] {kill|delete|del} : [番号]の問題中の[num]番のヒントを削除する。~%")
  ) ;; end print-hint-help

(defun print-answer-help ()
  (format t "[番号]+\"a)nswer\" : [番号]の現在の先頭問題に解答する。~%")
  (format t "[番号]のみ : [番号]+\"a)nswer\"と同じ。~%")
  (format t "[番号]+\"a)nswer\" {(mustbe (i j) k)|(cannotbe (i j) (k+))}+ : 解答を先行入力する。~%")
  (format t "[番号]+\"a)nswer\" [num] {(mustbe (i j) k)|(cannotbe (i j) (k+))}+ : [num]番の解答を先行入力する。~%")
  ) ;; end print-answer-help

(defun print-hint-info (board quiz-number function-name solution-info)
  (let (brd cell-expression comment cell-addr linked-label-list
	which-rule candidate common-candidate
#+ :sbcl tmp
	)

    (debug-write "pirnt-hint-info-0" (format nil "solution-info=~a~%" solution-info))
    (finish-output)
    (setq brd (new-board board))
    (setq cell-expression
	  (get-cell-expression function-name (nth quiz-number solution-info)))

    (debug-write "pirnt-hint-info-1" (format nil "cell-expression=~s~%" cell-expression))

    ;; [do-almost-locked-set]の場合、[get-cell-expression]は次の形式のリストを返す。
    ;; (list 'als-rule-1 (third solution-info) (first (last (third solution-info))))
    ;; (list 'als-rule-2 (third solution-info) (first (last (third solution-info))) common-cand)
    ;;
    ;; see also [get-almost-locked-set-cell-info]
    (setq which-rule (first cell-expression)) ;; for do-almost-locked-set
    (cond
      ((equal which-rule 'als-rule-1)
       (setq linked-label-list (third cell-expression))
       (debug-write "print-hint-info-1-5" (format nil "linked-label-list=~s~%" linked-label-list))
       )
      ((equal which-rule 'als-rule-2)
       (setq candidate (third cell-expression))
       (setq common-candidate (fourth cell-expression))
       )
      ) ;; end cond
    (cond
      ((member function-name '(do-almost-locked-set) :test #'equal)
       (setq cell-expression (second cell-expression))
       (debug-write "pirnt-hint-info-2" (format nil "cell-expression=~s~%" cell-expression))
       (setq brd (paint-cells brd (first cell-expression) 'blue))
       (setq brd (paint-cells brd (second cell-expression) 'green))
       (print-normal brd)
       (finish-output)
       )
      ((member function-name '(do-advanced-coloring) :test #'equal)
       (print-normal (third (nth quiz-number solution-info)))
       )
      (t
       (print-normal (paint-cells brd (parse-cell-expression cell-expression brd) 'blue))
       )
      ) ;; end cond

    (setq comment (hint-comment solution-info quiz-number))

    (cond
      ((and
	(stringp comment)
	(equal function-name 'do-nice-loop)
	(equal (first (third (nth quiz-number solution-info))) 'discontinuous)
	)
       (setq cell-addr (to-external-address-kernel (first (rest cell-expression))))
       (format t "~a 開始セルは ~a~%" (hint-comment solution-info quiz-number) cell-addr)
       )
      ((and
	(stringp comment)
	(equal function-name 'do-almost-locked-set)
	(equal which-rule 'als-rule-1)
	)
       (format t "~a : " (hint-comment solution-info quiz-number))
       (format t "Almost Locked Set ")
       (finish-output)
       (print-colored-string 'green "[A]" :text-or-background 'background-color)
       (finish-output)
       (format t "と")
       (finish-output)
       (print-colored-string 'blue "[B]" :text-or-background 'background-color)

       ;; at this point.
       ;; CORRUPTION WARNING in SBCL pid 24547 tid 24547:
       ;; Memory fault at (nil) (pc=0x5541822a [code 0x55417890+0x99A ID 0x788d],
       ;; fp=0x7e6c0777f5b8, sp=0x7e6c0777f560) tid 24547
       ;; The integrity of this image is possibly compromised.
       ;; Continuing with fingers crossed.

       (finish-output)
       #+ :sbcl (progn (setq tmp *print-pretty*) (setq *print-pretty* nil))
       (format t "は共通の候補数字~aによってリンク~%" linked-label-list)
       #+ :sbcl (setq *print-pretty* tmp)
       (finish-output)
       )
       ((and
	 (stringp comment)
	 (equal function-name 'do-almost-locked-set)
	 (equal which-rule 'als-rule-2)
	 )
	(format t "~a : " (hint-comment solution-info quiz-number))
	(format t "Almost Locked Set ")
	(print-colored-string 'green "[A]" :text-or-background 'background-color)
	(format t "と")
	(print-colored-string 'blue "[B]" :text-or-background 'background-color)
	#+ :sbcl (setq tmp *print-pretty*)
	#+ :sbcl (setq *print-pretty* nil)
	(format t "は候補数字~aにより相互にリンクし共通の候補数字~aが存在~%" candidate common-candidate )
	#+ :sbcl (setq *print-pretty* tmp)
	(finish-output)
	)
      ((stringp comment)
       ;; 2024-04-20 (恐らく)長い文字列を出力する場合、出来る限り行頭から出力するために改行してから出力する。
       ;; 少なくともCLISPとSBCLで、挙動が異なる。挙動が異なる場合は[*print-pretty*]を[nil]に設定することで
       ;; 挙動が一致する。
       (let (tmp)
	 (setq tmp *print-pretty*)
	 (setq *print-pretty* nil)
	 (format t "~a~%" (hint-comment solution-info quiz-number))
	 (setq *print-pretty* tmp)
	 )
       )
      ((listp comment)
       (dolist (p comment)
	 (format t "~a~%" p)
	 )
       )
      )
    ;;(if (zerop quiz-number) (format t "(*直前までの手筋により盤面が変化している可能性があります)~%"))
    (finish-output)
    ) ;; end let
  ) ;; end print-hint-info


(defun hint-comment (solution-info quiz-number)
  (let (hint-comment)
    (setq hint-comment (second (nth quiz-number solution-info)))
    (return-from hint-comment hint-comment)
    )	;; end let
  ) ;; end hint-comment

(defun answer-for (function-name-pair quiz-info-list)
  (let (brd node-num target-node function-name solution-info quiz-number-list quiz-number
	answer-list user-answer-list org-answer-list working-brd result row col number-of-colon)
    ;; [初期設定]
    ;;---------------------------------------------------------------------------------
    (setq function-name (car function-name-pair))
    (multiple-value-setq (solution-info node-num) (get-solution-info quiz-info-list function-name))
    (debug-write "answer-for-0"
		 (format nil "function-name=~a, solution-info=~s~%" function-name solution-info))

    (if (multi-position-function-p function-name) ;; 現時点では 'do-fundamental のみ。
	(setq solution-info (reduce-solution-info solution-info))
	)

    (setq target-node (find-node node-num))
    (setq brd (new-board (game-node-present-board (parent-node target-node))))

    (when (debug-write-p "answer-for-0")
      (print-normal brd)
      )

    (cond ;; 解答ごとに盤面を更新するケースに備えて更新用盤面を用意する。
      ((null (game-node-working-board target-node))
       (setq working-brd (new-board brd))
       (setf (game-node-working-board target-node) working-brd)
       )
      ((board-p (game-node-working-board target-node))
       (setq working-brd (new-board (game-node-working-board target-node)))
       )
      ) ;; end cond

    ;; [*multi-position-function*]に含まれる関数なら(game-node-grouped-quiz-list [node])の値を返す関数。
    (setq quiz-number-list (get-quiz-list target-node))
    ;;---------------------------------------------------------------------------------

    ;; [入力に応じた処理]
    ;;---------------------------------------------------------------------------------
    (debug-write "answer-for-1" (format nil "(rest-symbol)=~a~%" (rest-symbol)))
    (setq user-answer-list nil)
    (setq quiz-number nil)
    (cond
      ((pure-listp quiz-number-list)
       (debug-write "answer-for-2" (format nil "quiz-number-list=~a~%" quiz-number-list))
       (cond
	 ;;---------------------------------------------------------------------------------
	 ((<= (length (rest-symbol)) 1) ;; "answer" only. [番号]のみも[番号]+"answer"として扱う。
	  (setq quiz-number (pop quiz-number-list))
	  (setq answer-list (fourth (nth quiz-number solution-info))) ;; プログラムに記録されている解。

	  (setq number-of-colon "")
	  (dotimes (i (length answer-list))
	    (setq number-of-colon (concatenate 'string number-of-colon ":"))
	    )

	  (if (update-every-game-p function-name)
	      (print-hint-info working-brd quiz-number function-name solution-info)
	      (print-hint-info brd quiz-number function-name solution-info)
	      ) ;; end if

	  (loop
	    ;;===========================================================================================
	    (setq org-answer-list ;; 解答入力。
		  (enter-answer brd working-brd quiz-number function-name solution-info number-of-colon))
	    ;;===========================================================================================

	    (cond
	      ((member (first org-answer-list) '(quit q exit bye) :test #'equal) ;; 中止。
	       (return-from answer-for nil)
	       )
	      ((member (first org-answer-list) '(giveup give-up resign) :test #'equal) ;; ギブアップ。
	       (print-repeated-char-string 72 #\-)
	       (format t "解答は次の通りです。~%")
	       (print-problem-answer function-name quiz-number solution-info)
	       (setq quiz-number-list (remove quiz-number quiz-number-list :test #'=))
	       (set-quiz-list target-node quiz-number-list) ;; 消費したリストに更新。
	       (return-from answer-for nil)
	       )
	      ) ;; end cond
	    (setq user-answer-list (check-and-format-org-answer-list org-answer-list))
	    (if (identity user-answer-list)
		(return) ;; exit this loop
		)
	    ) ;; end loop

	  )
	 ;;---------------------------------------------------------------------------------
	 ((and ;; "answer"+[number]. 選択した手筋のヒント番号[number]に解答する。
	   (= (length (rest-symbol)) 2)
	   (integerp (second (rest-symbol)))
	   (member (second (rest-symbol)) quiz-number-list :test #'=)
	   )
	  (setq quiz-number (second (rest-symbol)))
	  (setq answer-list (fourth (nth quiz-number solution-info))) ;; プログラムに記録されている解。

	  (setq number-of-colon "")
	  (dotimes (i (length answer-list))
	    (setq number-of-colon (concatenate 'string number-of-colon ":"))
	    )

	  (if (update-every-game-p function-name)
	      (print-hint-info working-brd quiz-number function-name solution-info)
	      (print-hint-info brd quiz-number function-name solution-info)
	      ) ;; end if

	  (loop
	    ;;===========================================================================================
	    (setq org-answer-list ;; 番号指定での解答入力。
		  (enter-answer brd working-brd quiz-number function-name solution-info number-of-colon))
	    ;;===========================================================================================

	    (cond
	      ((member (first org-answer-list) '(quit q exit bye) :test #'equal) ;; 中止。
	       (return-from answer-for nil)
	       )
	      ((member (first org-answer-list) '(giveup give-up resign) :test #'equal) ;; ギブアップ。
	       (print-repeated-char-string 72 #\-)
	       (format t "解答は次の通りです。~%")
	       (print-problem-answer function-name quiz-number solution-info)
	       (setq quiz-number-list (remove quiz-number quiz-number-list :test #'=))
	       (set-quiz-list target-node quiz-number-list) ;; 消費したリストに更新。
	       (return-from answer-for nil)
	       )
	      ) ;; end cond
	    (setq user-answer-list (check-and-format-org-answer-list org-answer-list))
	    (if (identity user-answer-list)
		(return) ;; exit this loop
		)
	    ) ;; end loop

	  )
	 ;;---------------------------------------------------------------------------------
	 ((and ;; "answer"+{mustbe (i j) k) | (cannotbe (i j) (k+))}+
	   (>= (length (rest-symbol)) 2)
	   (not (integerp (second (rest-symbol))))
	   (pure-listp (rest-symbol))
	   )
	  (setq quiz-number (pop quiz-number-list))
	  (setq answer-list (fourth (nth quiz-number solution-info))) ;; プログラムに記録されている解。
	  (setq answer-list (reverse answer-list)) ;; 2024-04-15
	  (setq org-answer-list (rest-symbol))
	  (setq user-answer-list nil)
	  (dolist (p org-answer-list) ;; セル・アドレスを内部形式に変換。
	    (push (to-internal-address p) user-answer-list)
	    ) ;; end dolist
	  (setq user-answer-list (reverse user-answer-list))
	  (print-hint-info working-brd quiz-number function-name solution-info)
	  )
	 ;;---------------------------------------------------------------------------------
	 ((and ;; "answer"+[number]+{mustbe (i j) k) | (cannotbe (i j) (k+))}+
	   (>= (length (rest-symbol)) 3)
	   (integerp (second (rest-symbol)))
	   )
	  (setq quiz-number (second (rest-symbol)))
	  (setq answer-list (fourth (nth quiz-number solution-info))) ;; プログラムに記録されている解。
	  (setq org-answer-list (rest-symbol))
	  (setq user-answer-list nil)
	  (dolist (p org-answer-list) ;; セル・アドレスを内部形式に変換&正規化。
	    (push (cannotbe-or-mustbe-normal-form (to-internal-address p) 'reduce) user-answer-list)
	    ) ;; end dolist
	  (setq user-answer-list (reverse user-answer-list))
	  ;;(print-hint-info working-brd quiz-number function-name solution-info)
	  (if (update-every-game-p function-name)
	      (print-hint-info working-brd quiz-number function-name solution-info)
	      (print-hint-info brd quiz-number function-name solution-info)
	      ) ;; end if
	  )
	 ;;---------------------------------------------------------------------------------
	 ) ;; end inner cond
       ) ;; end (pure-listp quiz-number-list)
      ((null quiz-number-list)
       (format t "この手筋に対する解答はすべて終わっています。~%")
       (finish-output)
       (return-from answer-for nil)
       )
      ) ;; end cond

    ;; [答え合わせ]
    ;;---------------------------------------------------------------------------------
    (when (numberp quiz-number)
      (let (next-quiz-info next-quiz-answer-info-list row-2 col-2 cell-for-check ans pass
	    variation-list percentage max-cannotbe-candidate-length tmp)
	;; [answer] ::= (mustbe (x y) n) or (cannotbe (x y) (n1 n2..))
	;;(setq answer-list (fourth (nth quiz-number solution-info))) ;; プログラムに記録されている解。

	(debug-write "answer-for-4" (format nil "solution-info=~a~%" solution-info))
	(debug-write "answer-for-4" (format nil "answer-list=~a~%" answer-list))
	(debug-write "answer-for-4" (format nil "user-answer-list=~a~%" user-answer-list))

	(setq result nil)
	(dolist (p (unique (copy-seq user-answer-list) #'equal)) ;; 採点する。
	  ;; セル・アドレスから参照すべき解答を得る。
	  (setq ans (find (second p) answer-list :key #'second :test #'equal))
	  (debug-write "answer-for-5" (format nil "(answer brd ~a)=~a~%" ans (answer-variation brd ans)))

	  ;; 部分的に正しい解答を含む、全ての解答のバリエーションのリストを得る。
	  (setq variation-list (answer-variation brd ans))

	  ;; 部分解を含めた解答と答え合わせ。
	  (setq tmp (member p variation-list :test #'equal))
	  (debug-write "answer-for-5-1" (format nil "tmp=~a~%" tmp))

	  ;; 部分的に正しい解答を含む、全ての解答のバリエーションの中の最大の候補数字数を得る。
	  (setq max-cannotbe-candidate-length 0)
	  (dolist (q variation-list)
	    (when (equal (first q) 'cannotbe)
	      (if (> (length (third q)) max-cannotbe-candidate-length)
		  (setq max-cannotbe-candidate-length (length (third q)))
		  ) ;; end if
	      ) ;; end when
	    ) ;; end dolist
	  (debug-write "answer-for-5-2"
		       (format nil "max-cannotbe-candidate-length=~a~%" max-cannotbe-candidate-length))

	  (cond
	    ((null tmp)
	     (setq tmp 0)
	     )
	    ((and
	      (identity tmp)
	      (equal (first p) 'mustbe)
	      )
	     (setq tmp 1)
	     )
	    ((and
	      (identity tmp)
	      (equal (first p) 'cannotbe)
	      )
	     ;; 分母と分子のオリジナルの値が約分で失われないようにリスト形式で保存。
	     (setq tmp (list (length (third p)) max-cannotbe-candidate-length))
	     )
	    (t
	     (setq tmp 0)
	     )
	    ) ;; end cond
	  (push tmp result)
	  ) ;; end dolist

	(debug-write "answer-for-6" (format nil "result=~a~%" result))

	
	(cond
	  ((multiple-value-setq (pass percentage)
	     (do-grading result :grading-level (grading-level))) ;; 合否判定。
	   (setq quiz-number-list (remove quiz-number quiz-number-list :test #'=))
	   (set-quiz-list target-node quiz-number-list) ;; 消費したリストに更新。

	   (setq row (first (second user-answer-list)))
	   (setq col (second (second user-answer-list)))
	   (cond
	     ((equal (first user-answer-list) 'mustbe)
	      (setf (aref working-brd row col) (third user-answer-list))
	      )
	     ((equal (first user-answer-list) 'cannotbe)
	      (debug-write "answer-for-6"
			   (format nil "(aref working-brd ~d ~d)=~a, user-answer-list=~a~%"
				   row col (aref working-brd row col) user-answer-list)
			   )
	      (finish-output)
	      (setf working-brd (delete-candidate (third user-answer-list) row col working-brd))
	      )
	     )						   ;; end cond
	   (setq working-brd (clean-up-board working-brd)) ;; 削除・確定した情報を元に盤面を更新する。

	   (cond
	     ((conflict-p working-brd)
	      (format t "合格ですが盤面に矛盾が生じています。~%")
	      (format t "1番目の問題から順に正答することをお薦めします。~%")
	      (format t "正解は次の通りです。~%")
	      (print-problem-answer function-name quiz-number solution-info)
	      (print-problem-result result percentage)
	      (finish-output)

	      (setq tmp (color-mode))
	      (color-mode 0)
	      (print-normal working-brd)
	      (color-mode tmp)
	      (finish-output)
	      )
	     ((update-every-game-p function-name)
	      (print-colored-string 'green "合格です。盤面を整理して表示します。"
				    :text-or-background 'background-color :use-terpri t)
	      (format t "正解は次の通りです。~%")
	      (print-problem-answer function-name quiz-number solution-info)
	      ;;(format t "正解率は~6,2,,,f\%、合格基準は~,2,,,f\%以上でした。~%" percentage (grading-level))
	      (print-problem-result result percentage)
	      (print-problem-result result percentage)
	      (finish-output)

	      (setq working-brd (pm (clean-up-board working-brd)))
	      (setq tmp (color-mode))
	      (color-mode 0)
	      (print-normal working-brd)
	      (finish-output)
	      (color-mode tmp)
	      (setf (game-node-working-board target-node) working-brd) ;; 作業用盤面を更新する。
	      ;; 次以降の問題が解決済みに至っていないかをチェックする。
	      (dolist (p (get-quiz-list target-node))
		(setq next-quiz-info (nth p solution-info))
		(setq next-quiz-answer-info-list (fourth next-quiz-info))
		(dolist (next-quiz-answer-info next-quiz-answer-info-list) ;; cannotbe/mustbeはリスト。
		  (setq cell-for-check (second next-quiz-answer-info))
		  (setq row-2 (first cell-for-check))
		  (setq col-2 (second cell-for-check))
		  (when (integerp (aref working-brd row-2 col-2))
		    (print-repeated-char-string 72 #\-)
		    (format t "\*~aの問題~dのセル\(~d ~d\)=~aは確定値~dに変化したため問題をキャンセルします。~%"
			    (cdr function-name-pair) p (1+ row-2) (1+ col-2)
			    (aref brd row-2 col-2) (aref working-brd row-2 col-2)
			    )
		    (finish-output)
		    (setq quiz-number-list (remove p quiz-number-list :test #'=))
		    (set-quiz-list target-node quiz-number-list) ;; 消費したリストに更新。
		    ) ;; end when
		  )   ;; end dolist
		)     ;; end dolist
	      )	      ;; end (update-every-game-p function-name)
	     (t
	      (print-colored-string 'green "合格です。" :text-or-background 'background-color :use-terpri t)
	      (format t "正解は次の通りです。~%")
	      (debug-write "answer-for-6-3"
			   (format nil "function-name=~a, quiz-number=~a, solution-info=~a~%"
				      function-name quiz-number solution-info))
	      (print-problem-answer function-name quiz-number solution-info)
	      (print-problem-result result percentage)
	      (finish-output)
	      )
	     ) ;; end cond
	   )
	  ((not pass) ;; 不正解。
	   (print-colored-string 'red (format nil "~aは不合格です。" org-answer-list)
				 :text-or-background 'background-color :use-terpri t)
	   (print-problem-result result percentage)
	   (finish-output)
	   )
	  ) ;; end cond
	)   ;; end let
      )	    ;; end when
    ;;---------------------------------------------------------------------------------

    (if (and
	 (identity result)
	 (not (conflict-p working-brd))
	 )
	(return-from answer-for t)
	(return-from answer-for nil)
	) ;; end if

    ) ;; end let
  ) ;; end answer-for

(defun enter-answer (brd working-brd quiz-number function-name solution-info number-of-colon)
  "関数[answer-for]内でユーザからの解答入力を処理する関数。ヘルプ・コマンドなら該当する表示を行う。"
  (let (org-answer-list)
    (loop
      (format t "Enter answer (\"help\",\"\?\",\"again\" \"quit\") ~a " number-of-colon)
      (finish-output)
      (setq org-answer-list (read-multiple-symbol))
      (setq org-answer-list (cons org-answer-list (rest-symbol)))
      (debug-write "answer-for-3" (format nil "org-answer-list=~a~%" org-answer-list))

      (cond
	((not (member (first org-answer-list) '(help h \? again redisplay re) :test #'equal))
	 (return-from enter-answer org-answer-list) ;; exit this loop.
	 )
	((member (first org-answer-list) '(help h) :test #'equal)
	 (print-cannotbe-and-mustbe-help) ;; cannotbe, mustbe構文を説明するヘルプを表示。
	 )
	((equal (first org-answer-list) '?)
	 (print-colon-and-grading-help) ;; "Enter answer" プロンプトの":"の数と合格ラインの説明を表示。
	 )
	((member (first org-answer-list) '(again a redisplay re) :test #'equal) ;; view [brd] again.
	 (if (update-every-game-p function-name)
	     (print-hint-info working-brd quiz-number function-name solution-info)
	     (print-hint-info brd quiz-number function-name solution-info)
	     ) ;; end if
	 )
	) ;; end cond
      )	  ;; end loop
    )	  ;; end let
  ) ;; end enter-answer

(defun check-and-format-org-answer-list (org-answer-list)
  "外部セル・アドレス・フォーマットのcannotbe形式/mustbe形式のリストを受け取って、内部セル・アドレス・フォーマットに変換し、更に正しい形式かチェックして問題なければ変換後のリストを返す。そうでなければ[nil]を返す。"
  (let (user-answer-list)
    (setq user-answer-list nil)
    (dolist (p org-answer-list) ;; セル・アドレスを内部形式に変換。
      (push (to-internal-address p) user-answer-list)
      ) ;; end dolist
    (setq user-answer-list (reverse user-answer-list))
    (debug-write "check-and-format-org-answer" (format nil "user-answer-list=~a~%" user-answer-list))
	    
    (if (cannotbe-or-mustbe-list-p user-answer-list) ;; 正しい形式かどうかをチェック。
	(return-from check-and-format-org-answer-list user-answer-list)
	(format t "[(cannotbe (i j) (k+))]または[(mustbe (i j) k)]形式で解答を入力して下さい。~%")
	) ;; end if
    (return-from check-and-format-org-answer-list nil) ;; 形式チェックに不合格なら[nil]を返す。
    ) ;; end let
  ) ;; end check-and-format-org-answer-list

(defun do-grading (grading-list &key ((:grading-level grading-level) 100/100))
  "各問題ごとの正解・不正解を表す[t]と[nil]からなるリストを受け取って基準に従って合否を判定する。
合格なら[t]、不合格なら[nil]を返す。

(do-grading '(0 (1 3) 1 (1 2) 0) :grading-level  1/100) ==> returns [t]. ;; 0+(1/3)+1+(1/2)+0=11/6 >= 1/100
(do-grading '(0 (1 3) 1 (1 2) 0) :grading-level 30/100) ==> returns [t]. ;; 11/6 >= 30/100
(do-grading '(0 (1 3) 1 (1 2) 0) :grading-level 50/100) ==> returns [nil]. ;; (11/6)/5 < 50/100
"
  (let (total sum percentage)
    (setq sum 0)
    (dolist (p grading-list)
      (cond
	((null p)     ;; 念のため。
	 (do-nothing) ;; (incf sum 0)
	 )
	((numberp p)
	 (incf sum p)
	 )
	((pure-listp p) ;; 分母と分子のオリジナルの値が約分で失われないようにリスト形式で保存していた。
	 (incf sum (/ (first p) (second p)))
	 )
	) ;; end cond
      ) ;; end dolist
    (setq total (length grading-list))
    (setq percentage (* 100 (/ sum (length grading-list))))

    (debug-write "do-grading" (format nil "sum of grading-list=~d" sum))
    (debug-write "do-grading" (format nil "number of problems=~d" total))
    (debug-write "do-grading" (format nil "percentage=~6,2,,,f\%" percentage ))
    (return-from do-grading (values (>= (/ sum total) grading-level) percentage))
    ) ;; end let
  ) ;; end do-grading

(defun grading-level (&optional (level 1/100 sw))
  "合格ラインを設定する。
(glading-level) ==> 現在の合格ラインを返す。
(grading-level 80/100) ==> 合格ラインを80%に設定。
(grading-level nil) ==> デフォルトの合格ライン[1/100]に設定。

合格ラインは分数に限らずゼロより大きく1以下の任意の数に設定できる。
"
  (cond
    ((null sw)
     *grading-level*
     )
    ((null level)
     (setq *grading-level* 1/100)
     )
    ((and
      (numberp level)
      (plusp level)
      (<= level 1)
      )
     (setq *grading-level* level)
     )
    (t
     (error "grading-level : 合格ラインは100\%以下の正数\(\>0\)を設定して下さい。~%")
     )
    ) ;; end cond
  ) ;; end grading-level

(defun print-problem-answer (function-name quiz-number solution-info)
  (let (nth-solution-info-4 len p)
    (cond
      ((equal function-name 'do-nice-loop)
       (print-nice-loop-answer quiz-number solution-info)
       )
      ((equal function-name 'do-pattern-overlay-method)
       (print-pattern-overlay-method-answer quiz-number solution-info)
       )
      (t
       (setq nth-solution-info-4 (fourth (nth quiz-number solution-info)))
       (setq len (length nth-solution-info-4))
       (dotimes (i len)
	 (setq p (nth i nth-solution-info-4))
	 (if (= i (1- len))
	     (format t "~a~%" (to-external-address p))
	     (format t "~a " (to-external-address p))
	     ) ;; end if
	 )     ;; end dotimes
       )
      ) ;; end cond
    )	;; end let
  ) ;; end print-problem-answer

(defun print-nice-loop-answer (quiz-number solution-info)
  (let (info-4-list)
    (debug-write "print-nice-loop-answer"
		 (format nil "(nth ~d solution-info)=~s~%" quiz-number (nth quiz-number solution-info)))
    ;;(setq info-4-list (cannotbe-or-mustbe-normal-form (fourth (nth quiz-number solution-info))))
    (setq info-4-list (cannotbe-or-mustbe-normal-form (fourth (nth quiz-number solution-info)) 'reduce))
    (print-nice-notation (third (nth quiz-number solution-info)))
    (format t "~%  ==> ")
    (dolist (info-4 info-4-list)
      (print-elimination-list (list (list (second info-4) (list (first info-4) (third info-4)))) )
      ) ;; end dolist
    (terpri)
    (print-nice-board (third (nth quiz-number solution-info)))
    (finish-output)
    ) ;; end let
  ) ;; end print-nice-loop-answer

(defun print-pattern-overlay-method-answer (quiz-number solution-info)
  "関数[do-pattern-overlay-method]の[solution-info]の[:position]部は
	  (record-quiz-info :position (list num chk-brd patterns))
となっている。

[num] ::= 候補数字 ;
[chk-brd] ::= [num]が存在可能なセル位置が[t]、それ以外のセル位置が[nil]であるボード ;
[patterns] ::= [chk-brd]のうち、ナンプレのルール上有効な配置パターンであるボードのリスト ;
"
  (let (num chk-brd patterns brd nth-solution-info info-3 info-4 p len)
    ;; 下準備
    (setq nth-solution-info (nth quiz-number solution-info))
    (setq info-3 (third nth-solution-info))
    (setq info-4 (fourth nth-solution-info))
    (setq num (first info-3))
    (setq chk-brd (second info-3))
    (setq brd (new-board chk-brd))
    (setq patterns (third info-3))

    (format t "候補数字~dが存在できるセル位置:~%" num)
    (print-mini chk-brd)
    (format t "ナンプレのルールにより行・列・ブロック内の複数ヶ所に候補数字が存在するならば")
    (format t " 確定値は必ず、それぞれにひとつづつだけ存在する。この制約条件を満たす配置パターンは~d個~%"
	    (length patterns))
    (format t "*その全ての配置パターンに共通するセル位置があれば確定値")
    (format t "(有効な全ての配置パターンで共通なセル位置が確定値でないなら、")
    (format t "有効な配置パターンはゼロとなりナンプレのルールに矛盾)。~%")
    (format t "*全ての有効な配置パターンに1度も現れない候補のセル位置があれば、そのセル位置の候補は削除できる。~%")

    (format t "有効な配置パターンは次の通り。~%")
    (dotimes (i (length patterns))
      (format t "パターン~d~%" i)
      (print-mini (nth i patterns))
      ) ;; end dotimes
    (finish-output)

    (format t "以下の解が得られる(\"数値\"は確定値。\"@\"は確定値と同じ候補数字を削除できる位置)。~%")
    (dolist (p info-4)
      (cond
	((equal (first p) 'mustbe)
	 (setf (aref brd (first (second p)) (second (second p))) (third p))
	 )
	((equal (first p) 'cannotbe)
	 (setf (aref brd (first (second p)) (second (second p))) #\@)
	 )
	) ;; end cond
      ) ;; end dolist
    (print-mini brd)

    (setq len (length info-4))
    (dotimes (i len)
      (setq p (nth i info-4))
      (if (= i (1- len))
	  (format t "~a~%" (to-external-address p))
	  (format t "~a " (to-external-address p))
	  ) ;; end if
      )     ;; end dotimes
    )
  ) ;; end print-pattern-overlay-method-answer

(defun print-problem-result (result percentage)
  (let (lst)
    (setq lst (copy-seq result))
    (debug-write "print-problem-result" (format nil "result=~a, percentage=~d~%" result percentage))

    (do
     (
      (i 1 (incf i 1))
      (p (first lst) (pop lst))
      )
     ((null lst) nil)
      ;;(format t "i=~d, p=~a~%" i p)
      (cond
	((and
	  (numberp p)
	  (zerop p)
	  )
	 (format t "~d個目の解答=不正解でした。~%" i)
	 )
	((and
	  (numberp p)
	  (plusp p)
	  )
	 (format t "~d個目の解答=正解でした。~%" i)
	 )
	((pure-listp p)
	 (format t "~d個目の解答=削除できる候補数字~d個中、~d個正解でした。~%" i (second p) (first p))
	 )
	) ;; end cond
      )	  ;; end do
    (finish-output)

    (debug-write "print-problem-result" (format nil "result=~a, percentage=~d~%" result percentage))

    (cond
      ((and
	(pure-listp result)
	(= (length result) 1)
	)
       (format t "正解率は~5,1,,,f\%、合格基準は~,1,,,f\%以上でした。~%" percentage (* (grading-level) 100))
       )
      ((and
	(pure-listp result)
	(>= (length result) 2)
	)
       (format t "平均正解率は~5,1,,,f\%、合格基準は~,1,,,f\%以上でした。~%"
	       percentage (* (grading-level) 100))
       )
      ) ;; end cond
    (finish-output)
    ) ;; end let
  ) ;; end print-problem-result

(defun answer-variation (brd answer)
  "[answer]と部分的にでも候補数字を削除できる別解があれば、その別解を含めた全ての解を返す。
別解がなければ[answer]自身をリストにして返す。
部分的に解を満たすとは (cannotbe (i j) (k l m)) に対する (k l m)の1個から3個の候補数字の
組み合わせを要素とするcannotbe形式のこと。

[(pm sample-board-5)]
#=======================================================================#
# 1 2 . | 1 . . | 1 . . # . . . | . . . | . 2 . # . 2 . | . 2 . | . 2 . #
# 4 5 6 | 4 . 6 | 4 . 6 # . 7 . | . 3 . | 4 . 6 # . 5 6 | . . . | . . 6 #
# . . . | . . 9 | . . . # . . . | . . . | . . . # . . . | . 8 9 | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . 2 . # . . . | . . . | . 2 . #
# . 5 6 | . 3 . | . 7 . # . 8 . | . 5 . | . . 6 # . 1 . | . 4 . | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . 9 #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . . . # . 2 . | . . . | . 2 3 #
# 4 5 6 | . 8 . | 4 . 6 # . 9 . | 4 5 . | . 1 . # . 5 6 | . 7 . | . . 6 #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# B . . | B . . | . . . # . . . | . B . | . . . # . . . | . B B | B B B #
# B . . | B . . | . 5 . # . 6 . | B . . | . 8 . # . 9 . | . . . | . . . #
# B . . | B . . | . . . # . . . | . . . | . . . # . . . | . . . | B . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . 3 # . . . | . . . | . 2 . # . B . | . B B | . . . #
# . 9 . | 4 . 6 | 4 . 6 # . 5 . | . 7 . | 4 . . # . . B | . . . | . 8 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . . 6 | . . 6 | . 2 . # . 1 . | . 9 . | . 3 . # . 4 . | . 5 . | . . B #
# 7 8 . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | B . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . 3 . | . 2 . | . 9 . # . 4 . | . 1 . | . 7 . # . 8 . | . 6 . | . 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# 4 . . | . 5 . | . 8 . # . 2 . | . 6 . | . 9 . # . 3 . | . 1 . | 4 . . #
# 7 . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | 7 . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | 1 . . | 1 . . # . . . | . . . | . . . # . 2 . | . 2 . | . 2 . #
# 4 . 6 | 4 . 6 | 4 . 6 # . 3 . | . 8 . | . 5 . # . . . | . . . | 4 . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # 7 . . | . . 9 | 7 . 9 #
#=======================================================================#

この盤面で4行8列の3と4行9列の3は4行では唯一なので、4行では3は必ずどちらのセルに決まる。
従ってブロック6内の他の3は削除できる。これは正しくは(cannotbe (5 8) (3))だが(mustbe (5 8) 2)
でも誤りとは言えない。この「別解」を許容する。

実行例
[5]> (answer-variation brd '(mustbe (8 8) 2))
((mustbe (8 8) 2) (cannotbe (8 8) (4 7 9)))
[6]> (answer-variation brd '(cannotbe (8 8) (4 7 9)))
((cannotbe (8 8) (4 7 9)) (cannotbe (8 8) (4 7)) (cannotbe (8 8) (4 9))
 (cannotbe (8 8) (7 9)) (cannotbe (8 8) (9)) (cannotbe (8 8) (7)) (cannotbe (8 8) (4)))
"
  (let (candidate cell-addr set-diff-result comb-list result)
    (setq cell-addr (second answer))
    (setq candidate (aref brd (first cell-addr) (second cell-addr)))
    (debug-write "answer-variation" (format nil "canidate=~a~%" candidate))

    (setq result nil)
    (cond ;; セル内の候補数字がひとつなら確定値なので、そもそも別解は存在しない。
      ((integerp candidate)
       (setq result answer)
       )
      ((and
	(pure-listp candidate)
	(= (length candidate) 1)
	)
       (setq result answer)
       )
      ((equal (first answer) 'cannotbe)
       (setq comb-list nil)
       (dotimes (i (length (third answer))) ;; n個の候補数字に対して1個からn個までの候補数字の組み合わせを返す。
	 (setq comb-list (union comb-list (combination (third answer) (1+ i))))
	 ) ;; end dotimes
       (setq result nil)
       (dolist (p comb-list) ;; 全ての候補数字の組み合わせに対するcannobeリストを作る。
	 (push (list 'cannotbe cell-addr p) result)
	 ) ;; end dolist
       )
      ((equal (first answer) 'mustbe) ;; (mustbe (i j) m)形式なら等値な(cannotbe (i j) (k+))も返す。
       (setq set-diff-result (set-difference candidate (list (third answer)) :test #'equal))
       (setq result
	     (cons answer
		   (answer-variation brd (list 'cannotbe cell-addr (sort (copy-seq set-diff-result) #'<)))))
       )
      ) ;; end cond
    (return-from answer-variation result)
    )	;; end let
  ) ;; end answer-variation

(defun cannotbe-or-mustbe-normal-form (form-list &optional (expand-or-reduce 'reduce))
  "(恐らく正規化されていない)[cannotbe-form]と[mustbe-form]の混じったリストを受取り
正規化された[cannotbe-form]と正規化された[mustbe-form]の混じったリストを返す。"
  (let (result-1 result-2 cannotbe-form-list mustbe-form-list)

    (setq cannotbe-form-list nil)
    (setq mustbe-form-list nil)

    (dolist (p form-list)
      (cond
	((equal (first p) 'cannotbe)
	 (push p cannotbe-form-list)
	 )
	((equal (first p) 'mustbe)
	 (push p mustbe-form-list)
	 )
	) ;; end cond
      ) ;; end dolist

    (cond
      ((equal expand-or-reduce 'reduce)
       (setq result-1 (cannotbe-reduced-form cannotbe-form-list))
       (setq result-2 (mustbe-reduced-form mustbe-form-list))
       )
      ((equal expand-or-reduce 'expand)
       (setq result-1 (cannotbe-expanded-form cannotbe-form-list))
       (setq result-2 (mustbe-expanded-form mustbe-form-list))
       )
      ) ;; end cond

    (return-from cannotbe-or-mustbe-normal-form (append result-1 result-2))
    )	  ;; end let
  ) ;; end cannotbe-or-mustbe-normal-form

(defun cannotbe-reduced-form (cannotbe-form-list)
  "( (cannotbe (3 8) (3)) (cannotbe (3 8) (2)) (cannotbe (5 0) (7))
 (cannotbe (5 0) (6)) (cannotbe (8 7) (2)) )
==> ( (cannotbe (3 8) (2 3)) (cannotbe (5 0) (6 7)) (cannotbe (8 7) (2)) )
"
  (let (top lst-1 lst-2 matched result)
    (setq result nil)
    (setq lst-1 (copy-seq cannotbe-form-list))
    (loop
      (if (null lst-1) (return))
      (setq top (pop lst-1))
      (setq lst-2 (copy-seq lst-1))
      (setq matched nil)
      (dolist (p lst-1)
	(when (equal (second top) (second p))
	  (setq matched t)
	  (push (list 'cannotbe (second top) (sort (copy-seq (union (third top) (third p))) #'<)) result)
	  (setq lst-2 (remove p (copy-seq lst-2) :test #'equal))
	  ) ;; end when
	)   ;; end dolist
      (if (not matched) (push top result))
      (setq lst-1 (copy-seq lst-2))
      )	    ;; end loop
    (setq result (sort (unique (copy-seq result)) #'(lambda (x y) (cell-order-p (second x) (second y)))))
    (return-from cannotbe-reduced-form result)
    )	    ;; end lst
  )

(defun cannotbe-expanded-form (cannotbe-form-list)
  "(cannotbe (i j) k) と言う形式だった場合 (cannotbe (i j) (k)) と変換する。
(cannotbe (i j) (k+)) という形式だった場合 ( (cannotbe (i j) (k-1))...(cannotbe (i j) (k-n)) ) と変換する。
[cannotbe-form]のリストを受け取って、正規化した[cannotbe-form]のリストを返す。
"
  (let (result)
    (setq result nil)
    ;;(format t "cannotbe-form-list=~a~%" cannotbe-form-list)
    (dolist (cannotbe-form cannotbe-form-list result)
      (cond
	((irregular-cannotbe-form-p cannotbe-form)
	 (setq result (cons (list 'cannotbe (second cannotbe-form) (list (third cannotbe-form))) result))
	 )
	((normal-cannotbe-form-p cannotbe-form)
	 (dolist (p (third cannotbe-form) result)
	   (setq result (cons (list 'cannotbe (second cannotbe-form) (list p)) result))
	   ) ;; end dolist
	 )
	(t
	 (error "(cannotbe (i j) {k | (k+)})という形式の引数を与えて下さい。")
	 )
	) ;; end cond
      )	  ;; end dolist
    ;;(format t "result=~a~%" result)
    (return-from cannotbe-expanded-form
      (sort (unique (copy-seq result)) #'(lambda (x y) (cell-order-p (second x) (second y)))))
    )	  ;; end let
  ) ;; end cannotbe-expanded-form

(defun normal-cannotbe-form-p (exp)
  "正規のcannotbe形式なら[t]を返し、それ以外なら[nil]を返す。
正規のcannotbe形式とは cannotbe (i j) (k+)) という形式のこと。"
  (and ;; (cannotbe (i j) (k+))
   (pure-listp exp)
   (= (length exp) 3)
   (equal (first exp) 'cannotbe)
   (cell-addr-p (second exp))
   (pure-listp (third exp))
   )
  ) ;; end normal-cannotbe-form

(defun irregular-cannotbe-form-p (exp)
  "不正規のcannotbe形式なら[t]を返し、それ以外なら[nil]を返す。
不正規のcannotbe形式とは (cannotbe (i j) k) という形式のこと。"
  (and ;; (cannotbe (i j) k)
   (pure-listp exp)
   (= (length exp) 3)
   (equal (first exp) 'cannotbe)
   (cell-addr-p (second exp))
   (integerp (third exp))
   )
  )

(defun cannotbe-form-p (exp)
  (or
   (normal-cannotbe-form-p exp)
   (irregular-cannotbe-form-p exp)
   )
  ) ;; end cannotbe-form-p

(defun mustbe-reduced-form (mustbe-form-list)
  (mustbe-expanded-form mustbe-form-list)
  )

(defun mustbe-expanded-form (mustbe-form-list)
  "((mustbe (i j) (k+)))と言う形式だった場合 ((mustbe (i j) k)) と変換する。
[mustbe-form]のリストを受け取って、正規化した[mustbe-form]のリストを返す。"
  (let (result)
    (setq result nil)
    (dolist (mustbe-form mustbe-form-list result)
      (cond
	((irregular-mustbe-form-p mustbe-form)
	 (when (>= (length (third mustbe-form)) 2)
	   (warn "~a truncated to (mustbe ~a ~a)"
		 mustbe-form (second mustbe-form) (first (third mustbe-form)))
	   )
	 (setq result (cons (list 'mustbe (second mustbe-form) (first (third mustbe-form))) result))
	 )
	((normal-mustbe-form-p mustbe-form)
	 (setq result (cons mustbe-form result))
	 )
	(t
	 (error "(mustbe (i j) {k | (k+)})という形式の引数を与えて下さい。")
	 )
	) ;; end cond
      )	  ;; end dolsit
    (return-from mustbe-expanded-form
      (sort (unique (copy-seq result)) #'(lambda (x y) (cell-order-p (second x) (second y)))))
    )	  ;; end let
  ) ;; end mustbe-expanded-form

(defun normal-mustbe-form-p (exp)
  "正規のmustbe形式なら[t]を返し、それ以外なら[nil]を返す。
正規のmustbe形式とは (mustbe (i j) k) という形式のこと。"
  (and
   (pure-listp exp)
   (= (length exp) 3)
   (equal (first exp) 'mustbe)
   (cell-addr-p (second exp))
   (integerp (third exp))
   )
  ) ;; end normal-mustbe-form-p

(defun irregular-mustbe-form-p (exp)
  "不正規のmustbe形式なら[t]を返し、それ以外なら[nil]を返す。
不正規のmustbe形式とは (mustbe (i j) (k+)) という3番めの要素がリスト形式のもの。"
  (and ;; (mustbe (i j) (k))
   (pure-listp exp)
   (= (length exp) 3)
   (equal (first exp) 'mustbe)
   (cell-addr-p (second exp))
   (pure-listp (third exp))
   (integerp (first (third exp)))
   )
  ) ;; end irregular-mustbe-form-p

(defun mustbe-form-p (exp)
  (or
   (normal-mustbe-form-p exp)
   (irregular-mustbe-form-p exp)
   )
  ) ;; end mustbe-form-p

(defun cannotbe-or-mustbe-list-p (lst)
  "リスト[lst]の要素がmustbe形式かcannotbe形式だけであれば[t]、そうでなければ[nil]を返す。"
  (cond
    ((null lst)
     nil
     )
    ((symbolp lst)
     nil
     )
    ((pure-listp lst)
     (dolist (p lst)
       (if (not (or (cannotbe-form-p p) (mustbe-form-p p)))
	   (return-from cannotbe-or-mustbe-list-p nil)
	   )
       )
     (return-from cannotbe-or-mustbe-list-p t)
     )
    ) ;; end cond
  ) ;; end cannotbe-or-mustbe-list-p

(defun print-cannotbe-and-mustbe-help ()
  (print-repeated-char-string 72 #\-)
  (format t
"例えば、4行9列の内容(候補数字)が(1 2 3 7)のとき~%
セルの内容が「2, 3, 7のいずれでもない」が解答ならば(cannotbe (4 9) (2 3 7))と入力します。
セルの内容が「1」で確定ならば (mustbe (4 9) 1) と入力します。
本来、(cannotbe (4 9) (2 3 7))が正解の場合でも(mustbe (4 9) 1)も別解として許しています。~%")
  (format t
"
#=======================================================================#
# 1 2 . | 1 . . | 1 . . # . . . | . . . | . 2 . # . 2 . | . 2 . | . B . #
# 4 5 6 | 4 . 6 | 4 . 6 # . 7 . | . 3 . | 4 . 6 # . 5 6 | . . . | . . B #
# . . . | . . 9 | . . . # . . . | . . . | . . . # . . . | . 8 9 | . . B #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . 2 . # . . . | . . . | . B . #
# . 5 6 | . 3 . | . 7 . # . 8 . | . 5 . | . . 6 # . 1 . | . 4 . | . . B #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . B #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . 2 . | . . . | . . . # . . . | . 2 . | . . . # . 2 . | . . . | . B B #
# 4 5 6 | . 8 . | 4 . 6 # . 9 . | 4 5 . | . 1 . # . 5 6 | . 7 . | . . B #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#=======================#=======================#=======================#
# 1 . . | 1 . . | . . . # . . . | . 2 . | . . . # . . . | . B B | B B B #
# 4 . . | 4 . . | . 5 . # . 6 . | 4 . . | . 8 . # . 9 . | . . . | . . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | B . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | 1 . . | 1 . 3 # . . . | . . . | . 2 . # . B . | . B B | . . . #
# . 9 . | 4 . 6 | 4 . 6 # . 5 . | . 7 . | 4 . . # . . B | . . . | . 8 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . . 6 | . . 6 | . 2 . # . 1 . | . 9 . | . 3 . # . 4 . | . 5 . | . . B #
# 7 8 . | 7 . . | . . . # . . . | . . . | . . . # . . . | . . . | B . . #
#=======================#=======================#=======================#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# . 3 . | . 2 . | . 9 . # . 4 . | . 1 . | . 7 . # . 8 . | . 6 . | . 5 . #
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# . . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | . . . #
# 4 . . | . 5 . | . 8 . # . 2 . | . 6 . | . 9 . # . 3 . | . 1 . | B . . #
# 7 . . | . . . | . . . # . . . | . . . | . . . # . . . | . . . | B . . #
#-------+-------+-------#-------+-------+-------#-------+-------+-------#
# 1 . . | 1 . . | 1 . . # . . . | . . . | . . . # . 2 . | . 2 . | . B . #
# 4 . 6 | 4 . 6 | 4 . 6 # . 3 . | . 8 . | . 5 . # . . . | . . . | B . . #
# 7 . . | 7 . . | . . . # . . . | . . . | . . . # 7 . . | . . 9 | B . B #
#=======================================================================#
~%")
  (format t
"4行8列の内容が(2 3)のとき「2でない」は(cannotbe (4 8) (2))と書くのが正式ですが
(cannotbe (4 8) 2)と書くことも許しています。

同様に(mustbe (4 8) 3)を(mustbe (4 8) (3))と書くことも許容しています。
ただし(mustbe (9 9) (4 7 9))と書いた場合は2番目以降の候補数字(7 9)は切り捨てられます。

[行番号],[列番号],[候補数字]は9x9の通常のナンプレの場合 1..9の整数。~%")
  ) ;; print-cannotbe-and-mustbe-help

(defun print-colon-and-grading-help ()
  (format t "入力プロンプトの\"\:\"の数は入力すべき解答の数を表しています。~%")
  (format t "現在のレベル設定は~aです。~%" (selected-user-level))
  (format t "現在のレベル設定での合格基準は~5,1,,f\%以上です。~%" (float (* 100 (grading-level))))
  )

(defun reset-hint-info-and-working-board (quiz-info-list)
  (let (node-num-list temp p-node)
    (setq node-num-list (get-quiz-info-list-node-num-list quiz-info-list))
    (dolist (n node-num-list)
      (setq temp (find-node n))
      (setq p-node (parent-node temp)) ;; 2024-04-11
      (setf (game-node-quiz-list temp) (game-node-quiz-list-backup temp))
      (setf (game-node-grouped-quiz-list temp) (game-node-grouped-quiz-list-backup temp))
      (setf (game-node-working-board temp) ;; 作業用盤面も初期状態に戻す。
	    (game-node-present-board p-node)) ;; 2024-04-11
      ) ;; end dolist
    ) ;; end let
  )

(defun get-nice-loop-cell-info (nice-expression)
"Nice Loop成立情報からヒント表示に使用するセル情報を抽出する。

[Nice Loop成立情報]の形式例

(do-nice-loop \"非連続Nice Loop\"
 (discontinuous ((4 7) weak (-3) (3 8)) ((3 8) strong (3) (3 7)) ((3 7) weak (-3) (4 7)))
 (cannotbe (4 7) (3)))

上記例に対して[get-nice-loop-cell-info]は ((4 7) (3 8) (3 7)) を返す。
"
  (let (nice-cell-path result)
    (setq nice-cell-path (rest (third nice-expression)))
    (setq result nil)
    (dolist (p nice-cell-path)
      (if (cell-addr-p (first p)) (push (first p) result)) ;; セル・アドレス形態なら保存。
      ) ;; end dolist
    (setq result (reverse result))
    ;;(setq result (unique result))
    (return-from get-nice-loop-cell-info result)
    ) ;; end let
  )

(defun get-almost-locked-set-cell-info (solution-info)
  (cond
    ((equal (second solution-info) *ALS-rule-1*) ;; ALS rule 1
     ;; Almost Locked Set [A]とAlmost Locked Set [B]は候補数字[linked-label]によってリンクしている。
     ;; (record-quiz-info :position (list (reverse als-a) (reverse als-b) (first linked-labels)))
     (list 'als-rule-1
	   (remove (first (last (third solution-info)))
		   (copy-seq (third solution-info)) :from-end t :count 1)
	   (first (last (third solution-info))))
     )
    ((equal (second solution-info) *ALS-rule-2*) ;; ALS rule 2
     ;; Almost Locked Set[A]と[B]は候補数字[linked-label]により相互にリンクし,共通の候補数字
     ;; [common-cand]が存在する。
     ;; (record-quiz-info :position (list (reverse als-a) (reverse als-b) linked-label common-cand))
     (list 'als-rule-2
	   (remove (first (last (third solution-info)))
		   (copy-seq (third solution-info)) :from-end t :count 1)
	   (first (last (third solution-info)))
	   (fourth solution-info))
     )
    ) ;; end cond
  ) ;; end get-almost-locked-set-cell-info

(defun get-pattern-overlay-method-cell-info (solution-info)
  "[solution-info] ::= ([候補数字] [候補数字が存在するセル位置を保持する盤面] [有効なパターン盤面のリスト]) ;
"
  (let (cells brd)
    (setq cells nil)
    (setq brd (second (third solution-info)))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
	(if (aref brd i j)
	    (push (list i j) cells)
	    ) ;; end if
	) ;; end dotimes
      ) ;; end dotimes
    (return-from get-pattern-overlay-method-cell-info (reverse cells))
    ) ;; end let
  ) ;; end get-pattern-overlay-method-cell-info

(defun get-cell-expression (tesuji-function-name tesuji-info)
  "手筋実行関数に応じて手筋成立情報からヒントに使用するセル情報を抽出する。
セル情報を抽出する関数は必要に応じて記述する必要がある。
[tesuji-info] ::= (nth [num] (get-solution-info quiz-info-list 'do-fundamental))
                = (nth [num] [solution-info])
"
  (cond
    ((member tesuji-function-name '(do-fundamental do-localization do-n-tuples do-n-grid) :test #'equal)
     (third tesuji-info)
     )
    ((member tesuji-function-name '(do-nice-loop)) ;; :test #'equal)
     ;;(cons 'cell (get-nice-loop-cell-info tesuji-info))
     (cons 'chain (get-nice-loop-cell-info tesuji-info))
     )
    ((member tesuji-function-name '(do-almost-locked-set) :test #'equal) ;; may be do-GB-almost-locked-set.
     (get-almost-locked-set-cell-info tesuji-info)
     )
    ((member tesuji-function-name '(do-pattern-overlay-method) :test #'equal)
     (cons 'cell (get-pattern-overlay-method-cell-info tesuji-info))
     )
    ((member tesuji-function-name '(do-grid-based-almost-locked-set do-gb-als) :test #'equal)
     (cons 'cell (third tesuji-info))
     )
    ((member tesuji-function-name '(do-advanced-coloring) :test #'equal) ;; 2024-04-29
     (list tesuji-function-name)
     )
    (t
     (error "get-cell-expression : ~aに対するセル情報抽出方法が未定義です。" tesuji-info)
     )
    ) ;; end cond
  ) ;; end get-cell-expression

(defun show-information (quiz-info-list num)
  (let (number-of-kind number-of-tesuji mustbe-cells cannotbe-cells cells msg)
    (multiple-value-setq (number-of-kind number-of-tesuji)
      (get-tesuji-kind-and-number quiz-info-list))
    (multiple-value-setq (cells mustbe-cells cannotbe-cells) (remarkable-cells quiz-info-list))
    (setq cells cells) ;; 変数[cells]は使用していない。この式はコンパイラのwarningを消すためのダミー。
    (print-repeated-char-string 72 #\-)
    (finish-output)
    (format t "~8tこの盤面で成立している手筋は~d種類。~%" number-of-kind)
    (format t "~8t成立している個別の手筋数は~d個あります。~%" number-of-tesuji)
    (format t "~8t適用可能な手筋全体で候補が確定するセルは~d箇所、~%" mustbe-cells)
    (format t "~8t候補数字を削除できるセルは~d箇所あります。~%" cannotbe-cells)
    ;;(print-repeated-char-string 72 #\-)

    (format t "~8t~d+\"show\"で実際に使用されている手筋名の前に\"*\", ~d+\"hide\"で表示なし。~%" num num)
    (cond-print (format nil "設定が[novice-level], [middle-level]の場合は自動的に\"*\"を表示。~%")
		(member (selected-user-level) '(novice-level middle-level) :test #'equal))
    ;;(print-repeated-char-string 72 #\-)

    (setq msg "
            [手筋名番号]+\"hint\"は更に2つのオプション入力が可能です。

	    書式は[\"hint\" [num] [{kill | save}]]
	    \"[\"と\"]\"で囲まれた範囲はあってもなくてもOK。
            \"{\"と\"}\"で囲まれた範囲は\"|\"で区切られたいずれかの入力が必須です。
            \"kill\"は\"delete\",\"del\"でもOK。\"save\"は\"keep\"でもOKです。

            [手筋名番号]+\"restore\"と入力すると[手筋名番号]に対するヒント情報が復活します。
            \"restore\"は\"revive\"でもOKです。

	    [num]は手筋名の後ろに表示されているゼロから始まる数値のリスト内の数値。
	    ゼロから[n]までのn+1個の同一種類の手筋が成立していることを示しています。
	    指定しなければリストの先頭の番号から順に「消費」します。
	    「消費」と言うのは一旦表示したヒントは削除して2度と表示しないためです。
	    \"hint save\"とするとリストの先頭の数値に対応したヒントを表示しますが
            リスト内の数値は削除しません。
	    \"hint [num] save\"とするとリスト内の数値[num]に対応するヒントを表示しますが
	    数値は削除しません。
	    \"save\"を指定しないか\"kill\"を指定するとヒントを表示後に対応する
            数値[num]が削除されます。
	    数値[num]が指定されていなければリスト先頭の数値が削除されます。"
	  ) ;; end setq
    (cond-print (format nil "~a~%" msg) (long-explanation))

    (cond
      ((and
	(rest-symbol)
	(member (first (rest-symbol)) '(show s) :test #'equal)
	)
	(show-used-tesuji t)
	)
      ((and
	(rest-symbol)
	(member (first (rest-symbol)) '(hide h) :test #'equal)
	)
       (show-used-tesuji nil)
       )
      )
    ;;(print-repeated-char-string 72 #\-)
    (return-from show-information t)
    ) ;; end let
  ) ;; end show-information

(defun remarkable-cells (quiz-info-list)
"[quiz-info-list]に含まれる情報から候補数字を削除できるセルと候補数字が確定するセルのリストを返す。
[quiz-info-list]のデータ構造については (describe 'get-quiz-info-list) を参照。

返り値は

((cannotbe (0 1) (6)) (cannotbe (1 0) (6)) (cannotbe (2 6) (6)) (mustbe (2 8) 3)
 (cannotbe (3 0) (1)) (cannotbe (3 0) (7)) (cannotbe (3 1) (1)) (mustbe (3 7) 3)
 (cannotbe (3 8) (2)) (mustbe (3 8) 1) (cannotbe (4 1) (6)) (cannotbe (4 2) (6))
 (cannotbe (4 6) (2)) (cannotbe (4 7) (3)) (cannotbe (5 0) (6)) (cannotbe (5 8) (6))
 (cannotbe (7 8) (7)) (cannotbe (8 0) (7)) (cannotbe (8 1) (7)) (cannotbe (8 7) (2))
 (cannotbe (8 8) (7))) ;
3 ; ;; mustbe   セルの数。
18  ;; cannotbe セルの数。
"
  (let (cells mustbe-cells cannotbe-cells)
    (setf cells nil)
    (dolist (p (flatten-quiz-info-list quiz-info-list))
      ;;(format t "p=~a~%" p)
      (dolist (q (cdr p))
	;;(format t "q=~a~%" q)
	(if (identity q)
	    (setq cells (append cells (fourth q)))
	    ) ;; end if
	) ;; end dolist
      ) ;; end dolist

    (debug-write "remarkable-cells" (format nil "cells=~a~%" cells))

    (setq cells (sort (unique (copy-seq cells)) #'(lambda (x y) (cell-order-p (second x) (second y)))))

    (setq mustbe-cells 0)
    (setq cannotbe-cells 0)
    (dolist (p cells)
      (cond
	((equal (first p) 'cannotbe)
	 (incf cannotbe-cells)
	 )
	((equal (first p) 'mustbe)
	 (incf mustbe-cells)
	 )
	)
      ) ;; end dolist

    (return-from remarkable-cells (values cells mustbe-cells cannotbe-cells))
    ) ;; end let
  ) ;; end remarkable-cells

(defun get-quiz-info-list-node-num-list (quiz-info-list)
"[quiz-info-list]に含まれるノード番号の昇順のリストを返す。"
  (let (result)
    (setq result nil)
    (dolist (p quiz-info-list)
      (push (first p) result)
      ) ;; end dolist
    (return-from get-quiz-info-list-node-num-list (sort result #'<=))
    ) ;; end let
  ) ;; end get-quiz-info-list-node-num-list

(defun get-number-of-same-answer-group (quiz-info-list node-num)
"[quiz-info-list]に含まれる同じ解が得られる手筋グループの数を返す。"
  (let (count)
    (setq count 0)
    (dolist (p quiz-info-list)
      (when (= (first p) node-num)
	(setq count (length (second p)))
	(return-from get-number-of-same-answer-group count)
	) ;; end when
      ) ;; end dolist
    ) ;; end let
  ) ;; end get-number-of-same-answer-group

(defun get-same-answer-group (quiz-info-list node-num gr-num)
"[quiz-info-list]のノード番号[node-num]から同じ解が得られる[gr-num]番目の手筋情報のリストを返す。"
  (let (result)
    (setq result nil)
    (dolist (p quiz-info-list)
      (when (= (first p) node-num)
	(setq result (nth gr-num (second p)))
	(return-from get-same-answer-group result)
	) ;; end when
      )	  ;; end dolist
    )	  ;; end let
  ) ;; end get-same-answer-group

(defun get-tesuji-kind-and-number (quiz-info-list)
"[quiz-info-list]で成立している手筋の種類数、同一結果を得られる手筋群、そしてそれら手筋の合計数を返す。"
  (let (number-of-kind number-of-tesuji)
    (setf number-of-tesuji 0)

    ;; 同一の盤面に対して適用できる手筋の種類数を計算する。
    ;;(setf number-of-kind (length quiz-info-list))
    (setf number-of-kind 0)
    (dolist (p quiz-info-list)
      (if (identity (cdr p)) (incf number-of-kind))
      ) ;; end dolist

    (dolist (p (flatten-quiz-info-list quiz-info-list))
      (if (identity (cdr p))
	  (setf number-of-tesuji (+ number-of-tesuji (length (cdr p))))
	  ) ;; end if
      ) ;; end dolist

    (return-from get-tesuji-kind-and-number (values number-of-kind number-of-tesuji))
    )	;; end let
  ) ;; end get-tesuji-kind-and-number

(defun get-cell-address-info (answer-info)
"[手筋情報]からセル・アドレスに関する情報を取り出して返す。

[手筋情報] ::= ([手筋関数名] ({'mustbe | 'cannotbe} ({'col | 'row | 'block | 'house} [位置]
              ('cell [セル・アドレス] [対象数値]))) ;
[対象数値] ::= 'mustbe ==> 確定値 | 'cannotbe ==> 削除可能候補数字 ;
(do-fundamental unique-candidate (mustbe (row 3 (cell (3 7)) 3)))
    ==> (mustbe (row 3 (cell (3 7)) 3))"
  (third answer-info)
  )

(defun get-cell-address (answer-info)
  (third (second (third answer-info)))
  )

(defun get-tesuji-list (quiz-info-list)
"[quiz-info-list]に含まれる手筋関数名のリストを返す。"
  (let (result)
    (setq result nil)
    (dolist (p (flatten-quiz-info-list quiz-info-list))
      (push (first (second p)) result)
      ) ;; end dolist
    (setf result
	  (sort-as-simple-list
	   (copy-seq (unique result))
	   (mapcar #'car (function-name-to-tesuji-name-list)) #'equal))
    (return-from get-tesuji-list result)
    ) ;; end let
  ) ;; end get-tesuji-list

(defun print-node (node)
"引数で与えられたノード[node]の内容を表示する"
  (let (brd m state)
 
    (format t "Parent node : ~d (~s)~%" (game-node-parent-node-number node)
            (game-node-parent-node-label node))
    ;;(setf brd (game-node-prev-board node))
    (setf brd (parent-board node))
    (cond
      ((null brd)
       (format t "No previous board.~%"))
      ((board-p brd)
       (format t "Previous board :~%")
       (print-board (pm brd)))
      (t (error "board expected.")))
    (setf m (game-node-prev-methods node))
    (cond
      ((null m)
       (format t "No previous method.~%"))
      (t
       (format t "Previous method : ~a~%"
               (function-name-to-tesuji-name (game-node-prev-methods node))
               ;;(cdr (assoc (game-node-prev-methods node) (function-name-to-tesuji-name-list)))
               )
       )
      )
    (setf state (game-node-state node))
    (format t "state is ")
    (finish-output)
    (cond
      ((and
        (equal state 'finished)
        (>= (color-mode) 1))
       ;;(print-colored-string 'red "finished" 'text-color)
       (print-colored-string 'red "finished" :text-or-background 'background-color))
      ((and
        (equal state 'applied)
        (>= (color-mode) 1))
       ;;(print-colored-string 'green "applied" 'text-color))
       (print-colored-string 'green "applied" :text-or-background 'background-color))
      (t
       (format t "~a" (game-node-state node)) ;; monochrome output.
       )
      )
    (terpri)
    (finish-output)
    (format t "Present board : \#~d(~a)~%" (game-node-node-number node) (game-node-node-label node))
    (if (game-node-present-board node)
	(print-board (pm (game-node-present-board node)))
	(progn
	  (print-colored-string 'red (game-node-state node) :text-or-background 'background-color)
	  (format t "なので登録されている盤面はありません。~%")
	  )
	)
    (debug-write "quiz-info" (format nil "quiz-info is ~a" (game-node-quiz-info node)))
    ) ;; end let
  (return-from print-node t)
  )

(defun get-way-to-goal (node &optional (rule-key 'finished))
"木構造の解法手順を個々の解法手順に分離する

[finished-node-list] ::= ( ([解法ルート-1]) ([解法ルート-2]) ... );
[解法ルート・リスト]
   ::= ( ([親ノード番号] [ノード番号] [適用手筋名]) ... ) ;
[解法ルート-n] ::= ルート・ノードから解決盤面まで直前のリストの[ノード番号]が
   次の[解法ルート]の[親ノード番号]となるように連鎖するリスト。
先頭リストの[親ノード番号]は常に「0(ゼロ)」"
  (let (finished-node-list way-to-goal-list lst)
    (setf way-to-goal-list nil)
    (setf finished-node-list (collect-finished-node node rule-key))
    (dolist (p finished-node-list)
      (setf lst (make-way-to-goal p))
      (when (not (null lst))
        (push lst way-to-goal-list))
      ) ;; end dolist
    (return-from get-way-to-goal (reverse way-to-goal-list))
    ) ;; end let
  )

(defun make-way-to-goal (finished-node)
"[(game-node-state node)]が'finishedであるノードからルート・ノードまでの情報リストを返す。
リストの先頭がルート・ノード。
NEW [戻り値] ::= ( ([親ノード番号] [ノード番号] [適用手筋名]) ... ) ;"
  (let (result n p)
    ;;(format t "(make-way-to-goal ~s)~%" finished-node)
    (setf result nil)
    (cond
      ((null finished-node)
       (return-from make-way-to-goal result))
      ((null (find-node (first finished-node)))
       (return-from make-way-to-goal result))
      ((zerop (first finished-node))
       (return-from make-way-to-goal (list finished-node))))

    ;;(format t "make-way-to-goal-sub : f-node=~s~%" f-node)
    (push finished-node result)
    (setf n (first finished-node)) ;; n = parent node number
    (setf p (find-node n))         ;; p = parent node
    (loop
      (cond
        ((null p)
         (return-from make-way-to-goal result))
        ((null (game-node-parent-node-number p))
         (return-from make-way-to-goal result))
        ((root-node-p p) ;; root node?
         (return-from make-way-to-goal result)))
      (push (list
             (game-node-parent-node-number p)
             (game-node-node-number p)
             ;;(game-node-prev-board p)
             (game-node-prev-methods p)
             ;;(game-node-present-board p) ;; 2024-01-10
             )
            result)
      ;;(format t "make-way-to-goal-sub result = ~s~%" result)
      (setf n (game-node-parent-node-number p))
      ;;(format t "make-way-to-goal-sub : n = ~d~%" n)
      (setf p (find-node n))
      ) ;; end loop
    )   ;; end let
  )

(defun root-node-p (node)
  (= (game-node-node-number node) 0))


(defun collect-finished-node (node &optional (rule-key 'finished))
"解法手順リストから[game-node-state]が['finished]である末端ノードの情報だけを集める。

[game-node-state]が['finished]であるノードの[game-node-next-node]は必ず[nil]なので
全てのノード情報を集める場合は[game-node-next-node]が[nil]である末端ノードを集める。
その場合のオプショナル引数には['next-node-null]を指定する。

NEW [戻り値] ::= ( ([親ノード番号] [ノード番号] [適用手筋名] [現ノード盤面]) ... ) ;"
  (let (result) ;; [result] is global variable for local function collect-finished-node-sub.
    (setf result nil)
    (labels (
             (collect-finished-node-sub (node &optional (rule-key 'finished))
               (cond
                 ((null node)
                  (return-from collect-finished-node-sub result))
                 ((inspect-rule rule-key node)
                  (push (list
                         (game-node-parent-node-number node)
                         (game-node-node-number node)
                         ;;(game-node-prev-board node)
                         (game-node-prev-methods node)
                         ;;(game-node-present-board node) ;; 2024-01-10
                         )
                        result)))
               (when (null (game-node-next-node node))
                 (return-from collect-finished-node-sub nil))
               (dolist (p (game-node-next-node node))
                 (collect-finished-node-sub p rule-key))
               )
             )
      (collect-finished-node-sub node rule-key)
      ) ;; end labels
    (when (not (typep node 'game-node))
      (return-from collect-finished-node nil))
    (return-from collect-finished-node result)
    ) ;; end let
  )

(defun inspect-rule (rule-key p)
  (let (state)
    (setf state (game-node-state p))
    (cond
      ((equal state 'unsolved) nil)
      ((equal state 'inconsistent) nil)
      ((equal rule-key 'finished)
       (equal state 'finished))
      ((equal rule-key 'next-node-null)
       (null (game-node-next-node p)))
      (t nil))
    )
  )

(defun print-way-to-goal (node &optional (rule-key 'next-node-null))
  (let (n finished-node-list)
    ;; [finished-node-list] ::= ( ([解法ルート-1]) ([解法ルート-2]) ... );
    ;; [解法ルート・リスト]
    ;;    ::= ( ([親ノード番号] [ノード番号] [適用手筋名]) ... ) ;
    ;; ;;    ::= ( ([親ノード番号] [ノード番号] [適用手筋名]) ... ) ;
    ;; [解法ルート-n] ::= ルート・ノードから解決盤面まで直前のリストの[ノード番号]が
    ;;    次の[解法ルート]の[親ノード番号]となるように連鎖するリスト。
    ;; 先頭リストの[親ノード番号]は常に「0(ゼロ)」
    (setf finished-node-list (get-way-to-goal node rule-key))

    (cond
      ((and (null finished-node-list) (equal rule-key 'finished))
       (format t "現時点でゴールに到達している解き筋はありません。~%")
       (return-from print-way-to-goal nil) )
      ((and (null finished-node-list) (equal rule-key 'next-node-null))
       (format t "現時点で解き筋はありません。~%")
       (return-from print-way-to-goal nil))
      ) ;;end cond
    (dolist (finished-route-list finished-node-list)
      (setf n (second (nth (1- (length finished-route-list)) finished-route-list)))
      (format t "解法ルート[~d] : " n)
      (print-way-to-goal-sub finished-route-list)
      (terpri)
      )
    )
  )

;;; NEW [引数] ::= ( ([親ノード番号] [ノード番号] [適用手筋名]) ... ) ;
(defun print-way-to-goal-sub (finished-route-list)
  (let (p q n)
    (when (null finished-route-list)
      (return-from print-way-to-goal-sub nil))
    (loop
      (setf p (pop finished-route-list))
      (debug-write "print-way-to-goal-sub" (format nil "~s~%" p))
      (cond
        ((game-node-dead-route (find-node (first p))) ;; dead-routeの場合の表示。
         ;;(format t "\#~d ==(~a)==> " ;; [親ノード番号]と[適用手筋名]を出力。
         (format t (shaft-format-string *dead-end-shaft-string*)
                 ;; [親ノード番号]と[適用手筋名]を出力。
                 (first p)
                 (function-name-to-tesuji-name (third p))
                 )
         (when (null finished-route-list)
           (setf n (second p)) ;; node number
           (format t "\#~d" n)
           (setf q (find-node n))
           (format t "(Dead End)")
           (return))
         )
        (t ;; dead-routeでない場合の表示。
         ;;(format t "\#~d --(~a)--> " ;; [親ノード番号]と[適用手筋名]を出力。
         (format t (shaft-format-string *normal-shaft-string*)
                 (first p)
                 (function-name-to-tesuji-name (third p))
                 )
         (when (null finished-route-list)
           (setf n (second p)) ;; node number
           (format t "\#~d" n)
           (setf q (find-node n))
           (format t "(~a)" (game-node-state q))
           (return))
         )
        ) ;; end cond
      ) ;; end loop
    ) ;; end let
  )

(defun get-implication-node-number (node)
"[意味のあるノードのリスト]。[意味のあるノード]とは手筋を適用できたか解を得られたノードのこと。"
  (let (finished-node-list node-numbers)
    (setf node-numbers nil)
    (setf finished-node-list (collect-finished-node node 'next-node-null))
    (dolist (p finished-node-list)
      ;;(format t "p=~a~%" p)
      (push (second p) node-numbers)
      (push (first p) node-numbers))
    (setf node-numbers (sort (unique node-numbers) #'<))
    (return-from get-implication-node-number node-numbers)
    )
  )

(defun shaft-format-string (str)
    ;;(concatenate 'string "\#\~d " str "\(\~a\)" str "> ")
    (concatenate 'string "\#\~d" "\(\~a\)" str "> ")
  )

(defun save-way-to-goal (node &optional (rule-key 'finished) (fname "LogicalPath-" sw) (extention ".txt"))
"解法ルート情報をファイルに保存する。"
  (let (n p q finished-node-list)

    (cond
      ((null sw) ;; [fname]部分には何も指定されなかった。
       (setf fname (name-with-yyyymmdd fname extention)) )
      ;;(t (setf fname (format nil "~a~a" fname extention)) )
      (t (do-nothing)) ;; ユーザが拡張子の種別、有無も含めて指定したと見做す。
      ) ;; end cond

    ;; [finished-node-list] ::= ( ([解法ルート-1]) ([解法ルート-2]) ... );
    ;; [解法ルート・リスト]
    ;;    ::= ( ([親ノード番号] [ノード番号] [適用手筋名]) ... ) ;
    ;; [解法ルート-n] ::= ルート・ノードから解決盤面まで直前のリストの[ノード番号]が
    ;;    次の[解法ルート]の[親ノード番号]となるように連鎖するリスト。
    ;; 先頭リストの[親ノード番号]は常に「0(ゼロ)」
    (setf  finished-node-list (get-way-to-goal node rule-key))

    (cond
      ((and (null finished-node-list) (equal rule-key 'finished))
       (format t "現時点でゴールに到達している解き筋はありません。~%")
       (return-from save-way-to-goal nil) )
      ((and (null finished-node-list) (equal rule-key 'next-node-null))
       (format t "現時点で解き筋はありません。~%")
       (return-from save-way-to-goal nil))
      ) ;;end cond

    ;; 指定されたファイル[fname]が存在しないか、存在してもユーザが上書きを許可したら...
    (when
        (or
         (not (probe-file fname))
         (and
          (probe-file fname)
          ;;(yes-or-no-p "ファイル ~a は既に存在します。上書きしても良いですか？ " fname)
          ;; 上の行の日本語だと画面表示が乱れた。CLISP 2.49.93+ on Ubuntu 23.10
          ;; 行幅を超える日本語を含む長い文字列を出力すると画面が乱れるようだ。
          ;; そのため1行が長くならないように改行で区切った。
          (query-yes-or-no-p
           (format nil "ファイル ~a は既に存在します。~%上書きしても良いですか？" (truename fname)))
          )
         ) ;; end or
      ;; [finished-route-list] ::= ( ([親ノード番号] [ノード番号] [適用手筋名]) ... ) ;
      (with-open-file (s fname :direction :output :if-exists :overwrite :if-does-not-exist :create)
        (dolist (finished-route-list finished-node-list)
          (setf n (second (nth (1- (length finished-route-list)) finished-route-list)))
          (format s "解法ルート[~d] : " n)
          (loop
            (setf p (pop finished-route-list))
            (format s (concatenate 'string "\#~d " *normal-shaft-string* "(~a)" *normal-shaft-string* "> ")
                    (first p) ;; 親ノード番号
                    (function-name-to-tesuji-name (third p)) ;; 適用手筋名
                    )
            (when (null finished-route-list)
              (setf n (second p)) ;; node number
              (format s "\#~d" n)
              (setf q (find-node n))
              (format s "(~a)" (game-node-state q))
              (return))
            ) ;; end loop
          (terpri s)
          )
        )
      )
    )
  )

(defun save-node (node &optional (fname nil))
  (cond
    ((null fname)
     (format t "何というファイル名で保存しますか？ ")
     (finish-output)
     (setf fname (read-line))
     (clear-input)
     (when (zerop (length fname))
       (setf fname (default-node-file-name))
       ) ;; end when
     (pure-save-node node fname)
     ) ;; end (null fname)
    ((identity fname)
     (pure-save-node node fname)
     ) ;; end (identity fname)
    ) ;; end cond
  ) ;; end save-node

(defun pure-save-node (node fname)
  (cond
    ((not (probe-file fname)) ;; ファイル[fname]が存在しないなら、何も聞かずに書き込む。
     (with-open-file (s fname :direction :output :if-does-not-exist :create)
       (format s "\;\; Last node = ~d" (game-node-number)) ;; 最大ノード番号をコメントとして書き込んでおく。
       (format s "  ~a~%" (iso8601-date-string 'long 'date-and-time)) ;; 年月日時分秒も書き込んでおく。
       (format s "\'~a~%" node))
     (format t "*Saves ~a~%" (truename fname)) )
    ((probe-file fname) ;; ファイル[fname]が存在する。
     (cond
       ((plusp (auto-save-minutes)) ;; [(auto-save-minutes)]が正数なら、ユーザに何も聞かずに上書きする。
        (with-open-file (s fname :direction :output :if-exists :overwrite)
          (format s "\;\; Last node = ~d" (game-node-number)) ;; 最大ノード番号をコメントとして書き込んでおく。
          (format s "  ~a~%" (iso8601-date-string 'long 'date-and-time)) ;; 年月日時分秒も書き込んでおく。
          (format s "\'~a~%" node)
          (format t "*Saves ~a~%" (truename fname))))
       ((zerop (auto-save-minutes)) ;; auto saveしないなら追記する。
        (format t "解法過程データをファイル ~a に追記します。~%" fname)
        (with-open-file (s fname :direction :output :if-exists :append)
          (format s "\;\; Last node = ~d" (game-node-number)) ;; 最大ノード番号をコメントとして書き込んでおく。
          (format s "  ~a~%" (iso8601-date-string 'long 'date-and-time)) ;; 年月日時分秒も書き込んでおく。
          (format s "\'~a~%" node)
          (format t "*Saves ~a~%" (truename fname))) )
       ) ;; end cond
     ) ;; end (probe-file fname)
    ) ;; end outer cond
  )

(defun pure-save-data (sexp fname &optional (msg nil))
"引数で指定されたファイルに引数で指定されたS式[s-exp]を書き込む。
指定されたファイルが存在しなければ新しく作成して書き込み、ファイルが存在していれば追記する。
オプショナル引数が[nil]以外なら書き込んだファイル名情報を表示する。"
  (with-open-file (s fname :direction :output :if-exists :append :if-does-not-exist :create)
    (format s "\;\; UTC ~a~%" (iso8601-date-string 'long 'date-and-time))
    (if sexp (format s "~a" sexp))
    (when (not (null msg))
      (format t "*Saves ~a~%" (truename fname)))
    )
  )

(defun create-unique-name (&optional (prefix-name "sudoku-game-"))
  "引数で指定された文字列で始まるinternされた記号(変数名)を返す。
新しく作られたシンボルが既に存在していた場合は「次」のシンボルを生成して調べる。
これをinternした結果がユニークなものが見つかるまで繰り返す。したがって[create-unique-name]
が返すシンボルはinternされていてユニークであることが保証される。"
  (let (sym already-exist)
    (loop
      ;; 小文字のシンボルをinternすると"|"で囲まれたシンボル名になるので大文字でinternする。
      (multiple-value-setq (sym already-exist) (intern (string-upcase (symbol-name (gensym prefix-name)))))
      (if (not already-exist)
	  (return) ;; exit this loop.
	  ) ;; end if
      ) ;; end loop
    (return-from create-unique-name (values sym already-exist))
    )	;; end let
  ) ;; end create-unique-name

;;--------------------------------------------------------------------------------------

(defun short-date-string ()
  (iso8601-date-string 'short 'date-only)
  )

(defun long-date-and-time-string ()
  (iso8601-date-string 'long 'date-and-time)
  )

(defun name-with-yyyymmdd (&optional (fname "Default-") (extension ".lisp" sw))
  (let (str)
    (if (null fname) (setf fname "Default-"))
    (if (null sw) (setf extension ""))
    (setf str (format nil "~a~a~a"  fname (short-date-string) extension))
    (return-from name-with-yyyymmdd str)
    )
  )

(defun iso8601-date-string (&optional (long-or-short 'long) (date-and-time 'date-only))
"ISO 8601形式の文字列で年月日時分秒を返す。
引数は['short], ['long]と['date-and-time], ['date-only], ['time-only]の組み合わせ。
デフォルトは['long]×['date-only]。"
  (let (str yyyy mm dd hh minutes ss calender-value timezone)
    (setf calender-value (multiple-value-list (get-decoded-time)))
    (setf yyyy (nth 5 calender-value))
    (setf mm (nth 4 calender-value))
    (setf dd (nth 3 calender-value))
    (setf hh (nth 2 calender-value))
    (setf minutes (nth 1 calender-value))
    (setf ss (nth 0 calender-value))
    ;; 帰ってくるタイムゾーン値は「グリニッジ標準時(GMT)の西の時間数として表される整数」なので
    ;; GMTとして表わす場合は符号を逆にする。
    (setf timezone (- (nth 8 calender-value)))
    (cond
      ((and (equal long-or-short 'short) (equal date-and-time 'date-only))      ;; YYYYMMDD
       (setf str (format nil "~4,'0d~2,'0d~2,'0d" yyyy mm dd)))
      ((and (equal long-or-short 'short) (equal date-and-time 'time-only))      ;; HHMMSS
       (setf str (format nil "~2,'0d~2,'0d~2,'0d" hh minutes ss)))
      ((and (equal long-or-short 'short) (equal date-and-time 'date-and-time))  ;; YYYYMMDDTHHMMSS
       (setf str (format nil "~2,'0d~2,'0d~2,'0dT~2,'0d~2,'0d~2,'0d" yyyy mm dd hh minutes ss)))
      ((and (equal long-or-short 'long) (equal date-and-time 'date-only))       ;; YYYY-MM-DD
       (setf str (format nil "~4,'0d-~2,'0d-~2,'0d" yyyy mm dd)))
      ((and (equal long-or-short 'long) (equal date-and-time 'time-only))       ;; HH:MM:SS
       (setf str (format nil "~2,'0d:~2,'0d:~2,'0d" hh minutes ss)))
      ((and (equal long-or-short 'long) (equal date-and-time 'date-and-time))   ;; YYYY-MM-DDTHH:MM:SS±HH:MM
       (setf str (format nil "~4,'0d-~2,'0d-~2,'0dT~2,'0d:~2,'0d:~2,'0d~a"
                         yyyy mm dd hh minutes ss (timezone-time timezone))))
      ) ;; end cond
    (return-from iso8601-date-string str)
    )
  )

(defun timezone-time (&optional (hour (- (nth 8 (multiple-value-list (get-decoded-time))))))
"GMTを意味する\"+09:00\"\, \"-05:30\"という形式の文字列を返す。JST=GMT+09:00"
  (let (hour-part minute-part sign str)
    (if (< hour 0) (setf sign -1) (setf sign 1))
    (setf hour-part (truncate (abs hour)))
    (setf minute-part (truncate (* (- (abs hour) (truncate (abs hour))) 60)))
    (cond
      ((>= sign 0)
       (setf str (format nil "\+~2,'0d\:~2,'0d" hour-part minute-part)))
      ((minusp sign)
       (setf str (format nil "\-~2,'0d\:~2,'0d" hour-part minute-part)))
      )
    (return-from timezone-time str)
    )
  )

;;--------------------------------------------------------------------------------------

(defun default-node-data-fname-prefix (&optional (fname *default-node-data-fname-prefix* sw))
  (cond
    ((null sw)
     *default-node-data-fname-prefix*)
    ((stringp fname)
     (setf *default-node-data-fname-prefix* fname))
    (t *default-node-data-fname-prefix*))
  )

(defun default-games-fname-prefix (&optional (fname *default-games-fname-prefix* sw))
  (cond
    ((null sw)
     *default-games-fname-prefix*)
    ((stringp fname)
     (setf *default-games-fname-prefix* fname))
    (t *default-games-fname-prefix*))
  )

(defun save-node-data (node &optional (fname (default-node-data-fname-prefix) sw))
"[fname]を指定した場合は拡張子を含めて指定されたファイル名に書き出す。
指定がなければ(default-node-data-fname-prefix)の返す文字列に
実行時の年月日を加えたファイル名に書き出す。拡張子は[.lisp]。"
  (when (not (null sw))
    (pure-save-node node fname)
    (return-from save-node-data t)
    )
  (pure-save-node node (name-with-yyyymmdd fname ".lisp"))
  )

(defun load-node (&optional (load-from (default-node-file-name)))
  (load-node-or-games load-from 'node)
  )

(defun load-games (&optional (load-from (default-games-file-name)) (prefix-name "sudoku-game-") )
  (load-node-or-games load-from 'games prefix-name)
  )


(defun load-node-or-games (&optional (load-from (default-node-file-name))
                             (node-or-games 'games)
                             (prefix-name "sudoku-games-")
                             )
  (let (node result)
    (if (null load-from) (return-from load-node-or-games nil))

    (when (not (probe-file load-from))
      (format t  "ファイル ~a は存在しません。~%" load-from)
      (finish-output)
      (return-from load-node-or-games nil)
      )

    (debug-write "load-node-or-games" (format nil "Loading from ~a ...~%" (truename load-from)))

    (setq result (pure-load-sexp (truename load-from)))
    (if (null result)
	(return-from load-node-or-games nil)
	)

    (cond
      ((equal node-or-games 'games)
       (setf *sudoku-game-list*
             (append (pure-load-sexp load-from 'games prefix-name) *sudoku-game-list*))
       (setf *sudoku-game-list* (sort (copy-seq *sudoku-game-list*) #'string-lessp
				      :key #'(lambda (x) (symbol-name (first x)))))
       (return-from load-node-or-games *sudoku-game-list*)
       )
      ((equal node-or-games 'node)
       (setq node (pure-load-sexp load-from 'node))
       (return-from load-node-or-games node)
       )
      (t
       nil
       )
      ) ;; end cond
    ) ;; end let
  )

(defun pure-load-sexp (&optional (fname (default-node-file-name))
                         (node-or-games 'games)
                         (prefix-name "sudoku-game-")
                         )
"ファイル[fname]のS式をすべて読み込み形式を整える。
game-node型データだった場合は関数[examin]にセットする。
入力データ ::= ([setq] [name] [board型データ]) | ([setq] [name] [chunk型データ]) |
              [board型データ] | [chunk型データ] | [game-node型データ] ;
返り値 ::= ( ([setq] [name] [board型データ])* ) ;"
  (let (eos obj evaled-obj board-name board-body board-list)
    (setf eos (cons nil nil)) ;; eos means end of stream.
    (setf board-list nil)
    (with-open-file (s fname :direction :input)
      (loop
        (setf obj (read s nil eos))
        (if (eq obj eos) (return)) ;; exit loop
        (debug-write "pure-load-sexp" (format nil "obj=~a~%" obj))
        (setf evaled-obj (eval obj))
        (cond
          ((and ;; node型データの読み込み。
            (equal node-or-games 'node)
            (typep evaled-obj 'game-node))
           (root-node evaled-obj)
           (game-node-number (get-max-node-number evaled-obj))
           )
          ;; [borad-form] ::= ([setq] [name] [body]) ;
          ((and ;; [board-form] & [board型ボディ]
            (equal node-or-games 'games)
            (board-form-p obj)
            (board-p (third obj))
            )
           ;;(setf board-name (second obj))
           ;;(setf board-body (pm (third obj)))
           ;;(push (eval (list 'setq board-name board-body)) board-list)
	   (push obj board-list)
           )
          ((and ;; [board-form] & [chunk型ボディ]
            (equal node-or-games 'games)
            (board-form-p obj)
            (chunk-p (third obj))
            )
           ;;(setf (symbol-value board-name) board-body) ;; 2024-01-17
           (setf board-name (second obj))
           (setf board-body (pm (chunk2board (third obj))))
           (push (list 'setq board-name board-body) board-list)
           )
          ((and ;; [board型ボディ]単体のみのデータ(無名データ)
            (equal node-or-games 'games)
            (board-p obj)
            )
           (push (list 'setq (create-unique-name prefix-name) (pm obj)) board-list)
           )
          ((and ;; [chunk型ボディ]単体のみのデータ(無名データ)
            (equal node-or-games 'games)
            (chunk-p obj)
            )
           (push (list 'setq (create-unique-name prefix-name) (pm (chunk2board obj))) board-list)
           )
          (t
           (do-nothing)
           )
          )
        ) ;; end loop
      )   ;; end with-open-file

    (dolist (p board-list) ;; (setq [name] [board-data])を評価して[name]に値を持たせる。
      (eval p)
      ) ;; end dolist

    (return-from pure-load-sexp (reverse board-list))
    ) ;; end let
  )

(defun select-game-from-memory ()
  (let (select brd)
    (when (null *sudoku-game-list*)
      (format t "メモリ上にはナンプレ問題はありません。~%")
      (return-from select-game-from-memory nil)
      )
    (when (not (null *sudoku-game-list*))
      (setf *sudoku-game-list*
            (sort (copy-seq *sudoku-game-list*) #'string-lessp
                  :key #'(lambda (x) (symbol-name (first x)))))
      (dotimes (i (length *sudoku-game-list*))
	(print-repeated-char-string 25 #\-)
	(format t "~t~4d \= \(~a\)~%" i (first (nth i *sudoku-game-list*)))
	(print-mini (second (nth i *sudoku-game-list*)))
	) ;; end dotimes
      (loop
	(format t "Select number or name(中止は\"quit\") : ")
	(finish-output)
	(setf select (read))
	(clear-input)
	(cond
	  ((member select '(quit q exit) :test #'equal)
	   (return-from select-game-from-memory nil)
	   )
	  ((and
            (zero-or-positive-integerp select)
            (<= select (length *sudoku-game-list*))
            )
           (return)) ;; exit this loop.
	  ((and
	    (symbolp select)
	    (member select (mapcar #'first *sudoku-game-list*) :test #'equal)
	    )
	   (return) ;; exit this loop.
	   )
	  (t
	   (format t "正しい範囲の番号か登録済みの変数名を正しく入力して下さい。~%")
	   )
	  ) ;; end cond
	)   ;; end loop

      (cond
	((zero-or-positive-integerp select)
	 (setf brd (pm (second (nth select *sudoku-game-list*))))
	 (print-repeated-char-string 25 #\-)
	 (format t "~a~%" (first (nth select *sudoku-game-list*)))
	 )
	((symbolp select)
	 (setf brd (pm (eval select)))
	 (print-repeated-char-string 25 #\-)
	 (format t "~a~%" select)
	 )
	) ;; end cond
      (return-from select-game-from-memory brd) ;; 2024-05-01
      )
    ) ;; end let
  ) ;; end select-game-from-memory

(defun select-prefix-name (&optional (default-prefix-name "sudoku-game-"))
  (let (prefix-name)
    (format t "名前のない盤面データに対して文字+数字形式の一意な名前を与えます。~%")
    (format t "名前付きの盤面データの場合はオリジナルの名前のままです。~%~%")
    (format t "先頭部分の名前を指定できますが、自動的に付加される数値は連番とは限りません。~%")
    (format t "指定しない場合は(~a)で始まる名前になります。~%" prefix-name)
    (finish-output)
    (setq prefix-name default-prefix-name)
    ;; whenの条件部分に「長い」メッセージを与えると出力が乱れる？
    (when (query-y-or-n-p "先頭部分の名前を指定しますか？ ") ;; 2024-05-06
      (finish-output)
      (clear-input)
      (format t "Enter prefix-name : ")
      (finish-output)
      (setf prefix-name (read-line))
      (clear-input)
      (if (zerop (length prefix-name)) (setf prefix-name default-prefix-name))
      (format t "名前のない盤面データが存在した場合\"~a\"で始まる名前が与えられます。~%" prefix-name)
      (finish-output)
      ) ;; end when
    (return-from select-prefix-name prefix-name)
    ) ;; end let
  ) ;; end select-prefix-name

(defun select-game-from-file (&optional (fname nil) (prefix-name "sudoku-game-"))
  (let (board-list obj-num select brd)

    (cond ;; ファイル名として正しいか検証する。
      ((or
	(null fname)
	(not (stringp fname))
	)
       (return-from select-game-from-file nil)
       )
      ((not (probe-file fname))
       (return-from select-game-from-file nil)
       )
      ) ;; end cond

    ;; [(pure-load-sexp fname)]
    ;; ファイル[fname]のS式をすべて読み込み評価する。
    ;; game-node型データだった場合は関数[examin]用にセットする。
    ;; 入力データ ::= (['setq] [name] [board型データ]) | (['setq] [name] [chunk型データ]) |
    ;;               [board型データ] | [chunk型データ] | [game-node型データ] ;"
    (setf board-list (pure-load-sexp fname 'games prefix-name)) ;; read s-exps (symbolic expressions).
    (when (null board-list)
      (format t "盤面データは存在しませんでした。~%")
      (return-from select-game-from-file nil)
      )

    (debug-write "select-game-from-file" (format nil "board-list=~a~%" board-list))
    (debug-write "select-game-from-file"
		 (format nil "(mapcar \#\'second board-list)=~a~%" (mapcar #'second board-list)))

    (setf obj-num 0)
    (cond
      ((> (length board-list) 1)
       (dolist (p board-list) ;; 読み込んだs式（盤面データ）を番号付きで一覧表示する。
         (when (and
		(listp p)
		(board-p (third p))
		)
           (format t "\#~d \= ~a~%" obj-num (second p))
           (print-mini (pm (third p)))
           ) ;; end when
         (incf obj-num)
         ) ;; end dolist
       (loop
	 (format t "Select number or name(中止は\"quit\") : ")
	 (finish-output)
	 (setf select (read))
	 (clear-input)
	 (cond
	   ((member select '(quit q exit bye) :test #'equal)
	    (return-from select-game-from-file nil)
	    )
	   ((and
	     (zero-or-positive-integerp select)
	     (< select (length board-list))
	     )
	    (setq brd (eval (nth select board-list)))
            (return)) ;; exit this loop.
	   ((and
	     (symbolp select)
	     (member select (mapcar #'second board-list) :test #'equal)
	     )
	    (setq brd (eval select))
	    (return) ;; exit this loop.
	    )
	   (t
	    (format t "正しい範囲の番号か登録済みの変数名を正しく入力して下さい。~%")
	    )
	   )  ;; end cond
	 )    ;; end loop
       )

      ((= (length board-list) 1)
       (cond
         ((board-p (third (first board-list)))
          (setf brd (third (first board-list)))
          (format t "Read ~a~%" (first (first board-list)))
          (print-mini brd)
          )
	 (t
	  (format t "盤面データは存在しませんでした。~%")
	  (return-from select-game-from-file nil)
	  )
         )  ;; end cond
       )    ;; end (= (length board-or-fname) 1)
      (t
       (return-from select-game-from-file nil)
       )
      )
    (return-from select-game-from-file brd)
    ) ;; end let
  ) ;; end select-game-from-file

(defun board-form-p (obj)
  (cond
    ((not (listp obj)) nil)
    ((/= (length obj) 3) nil)
    ((not (member (first obj) '(setq setf))) nil)
    ((not (symbolp (second obj))) nil)
    ((not
      (or
       (board-p (third obj))
       (chunk-p (third obj)))) nil)
    (t t)
    )
  )


(defun get-max-node-number (node)
"[game-node]型データに含まれる最大のノード番号を返す。"
  (let (max-number)
    (setf max-number 0)
    (labels (
             (get-max-node-number-sub (node)
               (let (n)
                 (dolist (p (game-node-next-node node))
                   (setf n (game-node-node-number p))
                   (if (> n max-number) (setf max-number n))
                   (if (game-node-next-node p) (get-max-node-number-sub p))
                   ) ;; end dolist
                 )   ;; end let
               )     ;; end get-max-node-number-sub
             ) ;; end definition part of labels.
      (get-max-node-number-sub node)
      ) ;; end labels
    (return-from get-max-node-number max-number)
    ) ;; end let
  )

(defun find-all-logical-path-load (&optional (fname "All-path-" sw))
"[fname]を指定した場合は拡張子を含めて指定されたファイル名から読み込む。
指定がなければ[\"All-path-\"]に実行時の年月日を加えたファイル名から読み込む。拡張子は[.txt]。"
  (let (yyyy mm dd calender-date)
    (when (not (null sw))
      (load-node fname)
      (return-from find-all-logical-path-load t)
      )

    (setf calender-date (multiple-value-list (get-decoded-time)))
    (setf yyyy (nth 5 calender-date))
    (setf mm (nth 4 calender-date))
    (setf dd (nth 3 calender-date))
    ;; Makes "All-path-YYYYMMDD.data"
    (setf fname (format nil "~a~4,'0d~2,'0d~2,'0d\.txt" fname yyyy mm dd))
    (load-node fname)
    )
  )

;;--------------------------------------------------------------------------------------

(defun default-node-file-name
    (&optional (fname (name-with-yyyymmdd (default-node-data-fname-prefix) ".lisp") sw))
  (cond
    ((null sw) fname)           ;; 引数が指定されなければ "sudoku-yyyymmdd.lisp" という形式のファイル名を返す。
    ((and
      (not (null sw))           ;; 文字列が指定されれば、その文字列を返す。
      (stringp fname)) fname)
    ((null fname)               ;; わざわざ[nil]が指定されれば "sudoku-yyyymmdd.lisp"形式のファイル名を返す。
     (name-with-yyyymmdd (default-node-data-fname-prefix) ".lisp"))
    (t (symbol-name fname))     ;; 仕方ないので記号の印字名を返す。
    ) ;; end cond
  )

(defun default-games-file-name
    (&optional (fname (name-with-yyyymmdd (default-games-fname-prefix) ".lisp") sw))
  (cond
    ((null sw) fname)           ;; 引数が指定されなければ "sudoku-yyyymmdd.lisp" という形式のファイル名を返す。
    ((and
      (not (null sw))           ;; 文字列が指定されれば、その文字列を返す。
      (stringp fname)) fname)
    ((null fname)               ;; わざわざ[nil]が指定されれば "sudoku-yyyymmdd.lisp"形式のファイル名を返す。
     (name-with-yyyymmdd (default-games-fname-prefix) ".lisp"))
    (t (symbol-name fname))     ;; 仕方ないので記号の印字名を返す。
    ) ;; end cond
  )

(defun reset-sample-games ()
  (setf *sudoku-game-list* nil)
  )

(defun restore-sample-games ()
  (setf *sudoku-game-list* *sudoku-game-list-backup*)
  )

(defun auto-save-minutes (&optional (minutes 5 sw))
"一定時間ごとに自動保存する時間(分単位)を設定する。
必ずゼロか正数。ゼロ以下の数が指定されると[5]が設定される。
ゼロが指定されると自動保存しない。"
  (cond
    ((null sw)
     *auto-save-minutes*)
    ((and (numberp minutes) (<= 0 minutes))
     (setf *auto-save-minutes* minutes))
    (t (setf *auto-save-minutes* 5)))
  )

(defun inconsistent-case (&optional (pattern nil sw))
"適用条件を満たしているはずの盤面に手筋を適用したら盤面に矛盾が発生するケースを収集する。"
  (cond
    ((null sw) *inconsistent-case*)
    ((null pattern)
     (setf *inconsistent-case* nil))
    ((listp pattern)
     (push pattern *inconsistent-case*))
    (t (format t "List of \([`\[board\] \[method\] \[node number\]\) expected.~%"))
    )
  )

(defun reset-inconsistent-case ()
  (inconsistent-case nil)
  )

(defun allow-for-debug-command (&optional (mode nil sw))
  (cond
    ((null sw) *secret-command-for-debug*)
    ((null mode)
     (setf *secret-command-for-debug* nil))
    (t (setf *secret-command-for-debug* mode))
    )
  )

;;--------------------------------------------------------------------------------------

(defun query-yes-or-no-p (&optional (msg ""))
  "clispの(yes-or-no-p)は行頭なら改行なし。
sbclの(yes-or-no-p)は行頭でも改行あり。動作を統一するために定義した。"
  (let (str)
    (format t "~a (yes or no) " msg)
    (loop
      (finish-output)
      (setf str (read-line))
      (clear-input)
      (cond
	((string= (string-upcase str) "YES")
	 (return t)
	 )
	((string= (string-upcase str) "NO")
	 (return nil)
	 )
	) ;; end cond
      (format t "Please answer with yes or no : ")
      )	;; end loop
    )	;; end let
  )

(defun query-y-or-n-p (&optional (msg ""))
  "clispの(y-or-n-p)は行頭なら改行なし。
sbclの(y-or-n-p)は行頭でも改行あり。動作を統一するために定義した。"
  (let (str)
    (format t "~a (y or n) " msg)
    (loop
      (finish-output)
      (setf str (read-line))
      (clear-input)
      (cond
	((string= (string-upcase str) "Y")
	 (return t)
	 )
	((string= (string-upcase str) "N")
	 (return nil)
	 )
	) ;; end cond
      (format t "Please answer with y or n : ")
      )	;; end loop
    )
  )

;;--------------------------------------------------------------------------------------

(defun read-multiple-string ()
  "空白文字で区切られた1行中の複数のシンボルを分離して文字列のリストを返す。
大文字と小文字は入力されたまま。大文字・小文字変換は行わない。
先頭の文字列を第1の値として返し、2番目以降の文字列をリストにして返す。
[244]> (read-multiple-string)
I am a Boy.
\I\" ;
(\"am\" \"a\" \"Boy.\")
"
  (let (str string-list)
    (setq string-list nil)
    (setq str (read-line))
    (clear-input)
    (setq string-list (split-string str " ")) ;; 入力されたままの形で単語単位に分割したリストを返す。
    (setf *read-multiple-string* (cdr string-list)) ;; for [rest-of-multiple-read-string].
    (return-from read-multiple-string (values (first string-list) (cdr string-list)))
    ) ;; end let
  ) ;; end read-multiple-string

(defun rest-string ()
  (return-from rest-string *read-multiple-string*)
  )

(defun rest-of-multiple-read-string () (rest-string))

(defun reset-rest-string ()
  (setf *read-multiple-string* nil)
  )

;;--------------------------------------------------------------------------------------

(defun read-multiple-symbol ()
  (let (str symbol-list)
    (setq symbol-list nil)
    (clear-input)
    (setq str (read-line))
    (setq *original-read-string-list* (split-string str " ")) ;; 大文字・小文字の区別が必要な場合に使用する。
    (with-input-from-string (stream str :start 0)
      (do* ((eos (cons nil nil))
	    (sym (read stream nil eos) (read stream nil eos)))
	   ((eq sym eos) symbol-list)
	(debug-write "read-multiple-symbol" (format nil "sym=~s~%" sym))
	(push sym symbol-list)
	) ;; end do*
      ) ;; end with-input-from-string
    (setq symbol-list (reverse symbol-list))
    (setf *read-multiple-symbol* (cdr symbol-list)) ;; for [rest-of-multiple-read-symbol].
    (return-from read-multiple-symbol (values (first symbol-list) (cdr symbol-list)))
    ) ;; end let
  ) ;; end read-multiple-symbol

(defun original-read-string-list ()
  (return-from original-read-string-list *original-read-string-list*)
  )

#|
(defun split-string (str)
  "[str]内の英字を大文字・小文字変換しないまま単語に分割したリストを返す。"
  (let (string-list)
    (setq string-list nil)
    (set-macro-character #\; #'(lambda (ch) ch)) ;; セミコロンを無視する。
    (setf (readtable-case *readtable*) :preserve) ;; 大文字・小文字の変換を行わずに読み込む設定。
    (with-input-from-string (stream str :start 0)
      (do* ((eos (cons nil nil))
	    (sym (read stream nil eos) (read stream nil eos)))
	   ((eq sym eos) string-list)
	(debug-write "split-string" (format nil "sym=~s~%" sym))
	(push (format nil "~a" sym) string-list)
	) ;; end do*
      )	  ;; end with-input-from-string
    (setf (readtable-case *readtable*) :upcase) ;; 通常通りシンボル名は大文字で読み込む設定に戻す。
    (setq *readtable* (copy-readtable nil)) ;; 標準のCommon Lispリードテーブルに復帰する。
    (return-from split-string (reverse string-list))
    ) ;; end let
  )
|#

(defun rest-symbol ()
  (return-from rest-symbol *read-multiple-symbol*)
  )

(defun rest-of-multiple-read-symbol ()
  (rest-symbol)
  )

(defun reset-rest-symbol ()
  (setq *read-multiple-symbol* nil)
  )

;;--------------------------------------------------------------------------------------

(defun ignore-show-help (&optional (val nil sw))
"(ignore-show-help) ==> [t] なら[show-help]が[t]であってもメニュー表示しない。"
  (cond
    ((null sw)
     *ignore-show-help*)
    (t (setf *ignore-show-help* val))
    ) ;; end cond
  )

(defun cond-print (msg logical)
"条件指定[logical]が成立した場合のみメッセージ[msg]を表示する。"
  (if logical (format t msg))
  )

(defun show-used-tesuji (&optional (is-show nil sw))
  "メニューで手筋名を表示する際に、実際に使用された手筋名の先頭に\"*\"を表示するか設定する。"
  (cond
    ((null sw)
     *show-used-tesuji*
     )
    (t
     (setq *show-used-tesuji* is-show)
     )
    ) ;; end cond
  )

(defun print-step-around-menu ()
"関数[step-around]で選択できるメニュー項目用のメニューを表示する。
メニュー項目を追加・削除する場合は、下記の[cond-print]による表示項目以外に、[*step-around-menu-list*]も修正してコマンド名を入れ替えること。関数[menu-name]の最短文字数位置の計算に影響する。
"
  (let (fmt)

    ;; [288]> (step-around-menu-list)
    ;; (auto board change collection description dribble enter eval explore find goal guess help
    ;;  information level load lpr menu output pause quit read route save select store tesuji up
    ;;  version >>> $$$)
    ;; [289]> (make-menu-name-list (step-around-menu-list))
    ;; ((auto . "A)uto") (board . "B)oard") (change . "Ch)ange") (collection . "Co)llection")
    ;;  (description . "De)scription") (dribble . "Dr)ibble") (enter . "En)ter")
    ;;  (eval . "Ev)al") (explore . "Ex)plore") (find . "F)ind") (goal . "Go)al")
    ;;  (guess . "Gu)ess") (help . "H)elp") (information . "I)nformation") (level . "Le)vel")
    ;;  (load . "Lo)ad") (lpr . "Lp)r") (menu . "M)enu") (output . "O)utput") (pause . "P)ause")
    ;;  (quit . "Q)uit") (read . "Re)ad") (route . "Ro)ute") (save . "Sa)ve")
    ;;  (select . "Se)lect") (store . "St)ore") (tesuji . "T)esuji") (up . "U)p")
    ;;  (version . "V)ersion") (>>> . ">)>>") ($$$ . "$)$$"))
    ;;
    ;; 以後、(menu-name [command-name] [menu-name-list])でメニューに表示すべき文字列が返る。
    ;; [285]> (menu-name 'auto)
    ;; \"A)uto\"
    ;; [286]> (menu-name 'e)
    ;; nil
    ;; [287]> (menu-name 'eval)
    ;; \"Ev)al\"
    ;;
    ;; [*menu-name-pair-list*]は[menu-name]関数の第2引数のデフォルト引数。
    (setq *menu-name-pair-list* (make-menu-name-list :menu-name-list (step-around-menu-list) :front "\ "))

    (setf fmt (format nil "~~~d,8T" 16)) ;; 書式指示子を動的に作る。この引数だけで全体を調節できる。
    ;;(format t "~s" fmt) returns "~16,8T"
    (cond-print (concatenate 'string (menu-name 'information) fmt "現在の盤面と付随する情報を表示します。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string (menu-name 'pause) (format nil "\(~d\)" (pause-number))
                             fmt "指定した盤面数を出力するごとに一時停止します。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string (menu-name 'tesuji) fmt "現在の盤面に適用可能な手筋一覧を表示します。~%")
                (and (not (ignore-show-help)) (minimum-explanation)))
    (cond-print (concatenate 'string (menu-name 'description) fmt
			     "指定されたルート番号の解法過程を表示します。~%")
                (and (not (ignore-show-help)) (minimum-explanation)))
    (cond-print (concatenate 'string fmt "カレント・ノードが指定されたルート番号のノードに変わります。~%")
                (and (not (ignore-show-help)) (minimum-explanation)))
    (cond-print (concatenate 'string fmt "数値を直接入力することも出来ます。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'guess) fmt "検討中の盤面を使って手筋習得練習を行います。~%")
                (and (not (ignore-show-help)) (minimum-explanation)))
    (cond
      ((and (dribble-p) (can-dribble) (not (ignore-show-help))
            (or (normal-explanation) (long-explanation))) (format t "\*")) ;; dribble中は行頭に"*"
      ((and (not (dribble-p) ) (can-dribble) (not (ignore-show-help))
            (or (normal-explanation) (long-explanation))) (format t "\ "))
      ) ;; end cond
    (cond-print (concatenate 'string (subseq (menu-name 'dribble) 1) fmt ;; 先頭の空白文字を削除。
			     "画面出力を指定したファイルに保存します。~%")
                (and (or (normal-explanation) (long-explanation)) (can-dribble) (not (ignore-show-help))))
    (cond-print (concatenate 'string fmt
                             (format nil "~aで使用可能な処理系依存機能です。~%" (lisp-implementation-type)))
                (and (or (normal-explanation) (long-explanation)) (can-dribble) (not (ignore-show-help))))
    (cond-print (concatenate 'string (menu-name 'goal) fmt "解決済みの解き筋を表示します。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'route) fmt "現時点までに判明している解き筋を表示します。~%")
                (and (not (ignore-show-help)) (minimum-explanation)))
    (cond-print (concatenate 'string (menu-name 'explore) fmt
			     "全ての解法過程ルートを探索します。一時停止設定も可。~%")
                (and (not (ignore-show-help)) (allow-explore)))
    ;;(cond-print (concatenate 'string fmt "画面表示後に結果をファイルに保存することも出来ます。~%")
    ;;      (and (not (ignore-show-help)) (allow-explore) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'auto) " save" (format nil "\(~d\)" (auto-save-minutes))
                             fmt "解法過程の途中結果を設定分数ごとにファイルに保存します。~%")
                (and (not (ignore-show-help)) (allow-explore)))
    (cond-print (concatenate 'string fmt "Exploreコマンドでの一時停止設定が優先します。~%")
                (and (not (ignore-show-help)) (allow-explore) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'board) fmt
			     "候補数字ありの盤面と、なしの小さな盤面を切り替えます。~%")
                (and (not (ignore-show-help)) (minimum-explanation)))
    (cond-print (concatenate 'string (menu-name 'find) fmt
			     "指定されたノード番号/ラベルを持つノードに移動します。~%")
                (and (not (ignore-show-help)) (minimum-explanation)))
    (cond-print (concatenate 'string (menu-name 'change) fmt "現在のノードのラベルを変更します。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'up) fmt "親ノードに移動します。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'save) fmt "現時点までの解法経路情報を保存します。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'load) fmt "ファイルから解法経路情報を読み込みます。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string fmt "最後に読み込んだ解法経路情報を関数[examin]のデータとして設定します。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string fmt "検討を中断した状態から再開できます。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    ;;(cond-print (concatenate 'string fmt "複数の名前付き盤面データを保存したファイルを読み込めば~%")
    ;;            (and (not (ignore-show-help)) (long-explanation)))
    ;;(cond-print (concatenate 'string fmt "\[New game\]で複数の盤面データを切り替えて検討できます。~%")
    ;;            (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'output) fmt
			     "現時点までの解法ルート図\(テキスト\)を保存します。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string fmt "解法ルート情報が存在しなければ保存用ファイルも作成されません。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'select) " Game" fmt
			     "ナンプレ問題を選択します。ナンプレ問題群のリセットもここ。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string (menu-name 'Enter) " Game" fmt "ナンプレ問題を新規に手入力します。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string (menu-name 'Store) " Games" fmt
			     "メモリ上の全てのナンプレの問題をファイルに保存します。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string (menu-name 'Read) " games" fmt
			     "ファイルからナンプレの問題を読み込みます。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string fmt "名前を指定していないナンプレ問題に半自動で名前を付けます。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'Collection) fmt "現在の盤面をファイルに追記します。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string (menu-name 'Lpr) fmt "指定するノード番号の盤面を印刷します。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (when (and
           (allow-for-debug-command)
           (inconsistent-case)
           )
      (cond-print (concatenate 'string (menu-name '\$\$\$) fmt "盤面に矛盾を生じたケースがあれば表示します。~%")
                  (and (not (ignore-show-help)) (allow-for-debug-command)))
      (cond-print (concatenate 'string (menu-name '\>\>\>) fmt
			       "盤面に矛盾を生じたケースをファイルに追記保存します。~%")
                  (and (not (ignore-show-help)) (allow-for-debug-command)))
      ) ;; end when
    (cond-print (concatenate 'string (menu-name 'Level) fmt
			     "使用する手筋と手筋に対する制限を5段階から選びます。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'Menu) fmt "メニューの表示量を3段階で選びます。現在は"
                             (format nil "~aです。~%" (examin-message-level)))
                (and (not (ignore-show-help)) (minimum-explanation)))
    (cond-print (concatenate 'string (menu-name 'Eval) fmt "設定変更用関数などを評価する。~%")
		(and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string (menu-name 'quit) fmt "検討を終了します。~%")
                (and (not (ignore-show-help)) (normal-explanation)))
    (cond-print (concatenate 'string (menu-name 'help) fmt "短い手筋解説を表示します。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (cond-print (concatenate 'string (menu-name 'Version) fmt
			     "実行中のNumberPlace.lispのバージョンを表示します。~%")
                (and (not (ignore-show-help)) (long-explanation)))
    (finish-output)
    (return-from print-step-around-menu t)
    )
  )

(defun label-exist-p (str)
"大域変数[*game-label-list*]に文字列[str]が既に含まれていれば[t]、含まれていなければ[nil]を返す。
[nil]は[*game-label-list*]には登録していない。登録しているラベルは全て文字列。"
  (if (not (stringp str)) (return-from label-exist-p nil))
  (member str (game-label-list) :key #'first :test #'string=)
  )

(defun change-node-label (node &optional (new-label nil))
  "指定されたノード[node]のラベルを入力された文字列に置き換える。ラベルは大文字と小文字を区別する。
文字列 \"nil\"(大文字・小文字混在可) または、空文字列を指定すると指定されたラベルを削除する。"
  (let (str c-lbl)
    (setf c-lbl (game-node-node-label node)) ;; current label.
    (cond
      ((null new-label)
       (cond
	 ((null c-lbl)
	  (format t "ラベルは設定されていません。登録するラベルを入力してください。: ")
	  (finish-output)
	  (setf str (read-line))
	  (clear-input)
	  (if (or
	       (string= (string-downcase str) "nil")
	       (string= str "")
	       )
	      (setf str nil)
	      ) ;; end if
	  (when (label-exist-p str)
            (format t "~a と言うラベルは既に登録されています。別のラベルを指定してください。~%" str)
            (change-node-label node nil)
            (return-from change-node-label node)
	    ) ;; end when
	  (setf (game-node-node-label node) str) ;; [nil]または、存在していないラベルなのでノードに設定。
	  (when (not (null str)) ;; ただし[nil]は[*game-label-list*]には登録しない。
	    (push (list str (game-node-node-number node)) *game-label-list*)
	    )
	  )
	 (t ;; 現在のノード[node]にはラベルが設定されている。
	  (format t "現在のラベルは ~a です。変更するラベルを入力してください(中止は\"quit\")。: "
		  (game-node-node-label node))
	  (setq *game-label-list* ;; 現在のラベル[c-lbl]を[*game-label-list*]から削除。
		(remove c-lbl *game-label-list* :key #'car :test #'string=))
	  (loop
            (setf str (read-line))
            (clear-input)
            (cond
	      ((member (string-upcase str) '("QUIT" "Q" "EXIT" "BYE") :test #'string=)
	       ;; 元の状態に復旧して終了。
	       (setf (game-node-node-label node) c-lbl)
	       (push (list c-lbl (game-node-node-number node)) *game-label-list*)
	       (return-from change-node-label nil)
	       )
              ((or
		(string= (string-downcase str) "nil")
		(string= str "")
		)
               (setf (game-node-node-label node) nil)
               (return-from change-node-label node)
	       )
              ((label-exist-p str)
               (format t "~a は既に登録されているラベルなので使用できません。~%" str)
               (finish-output)
               (format t "変更するラベルを入力し直してください。: ")
               (finish-output)
	       )
              (t
	       (return)
	       )
	      ) ;; end cond
            ) ;; end loop
	  (setf (game-node-node-label node) str)
	  (push (list str (game-node-node-number node)) *game-label-list*)
	  )
	 ) ;; end cond
       )
      ((identity new-label) ;; 先行入力があった。
       (setf str new-label)
       (if (or
	    (string= (string-downcase str) "nil")
	    (string= str "")
	    )
	   (setf str nil)
	   ) ;; end if
       (cond
	 ((and ;; 現在のラベルが[nil]で、変更しようとしているラベルと同じ名前のラベルは登録されていない。
	   (null c-lbl)
	   (not (label-exist-p str))
	   )
	  (setf (game-node-node-label node) str)
	  (when (not (null str))
	    (push (list str (game-node-node-number node)) *game-label-list*)
	    ) ;; end when
	  )
	 ((identity c-lbl) ;; 現在のラベルは[nil]ではない。
	  (setf *game-label-list* ;; 現在のラベルを一旦[*game-label-list*]から削除。
		(remove (game-node-node-label node) *game-label-list* :key #'car :test #'string=))
	  (cond
	    ((not (label-exist-p str)) ;; 同じ名前のラベルが登録されていない。
	     (setf (game-node-node-label node) str)
	     (when (not (null str))
	       (push (list str (game-node-node-number node)) *game-label-list*)
	       ) ;; end when
	     )
	    (t ;; 変更しようとしているラベルと同じ名前のラベルが既に登録されている。
	     (setf (game-node-node-label node) c-lbl) ;; 元のラベルを保存し直す。
	     (push (list c-lbl (game-node-node-number node)) *game-label-list*)
	     )
	    ) ;; end cond
	  )   ;; end new-label
	 )    ;; cond
       )      ;; end new-label
      )	      ;; end first cond
    )	      ;; end let
  (return-from change-node-label node)
  ) ;; end change-node-label

(defun function-name-to-tesuji-name-list (&optional (language 'english sw))
"手筋を実現する関数名と手筋名のペア･リストを返す。"
  (cond
    ((null sw)
     *function-name-to-tesuji-name*)
    ((and sw (equal language 'english))
     (setf *function-name-to-tesuji-name* *english-function-name-to-tesuji-name*)
     )
    ((and sw (equal language 'japanese))
     (setf *function-name-to-tesuji-name* *japanese-function-name-to-tesuji-name*)
     )
    )
  )

(defun function-name-to-tesuji-name (function-name)
  (cdr (assoc function-name (function-name-to-tesuji-name-list)))
  )

(defun null-string-p (str)
  (zerop (length str))
  )

(defun numberplace-version ()
  (return-from numberplace-version *version*)
  )

(defun repeated-char-string (num ch)
"character型引数[ch]が[num]回続く文字列を返す。 2024-01-30

(format nil \"~~~d,,,\'\~c\a\" num ch ch) ==> \"~[num],,,'[ch]a\"
[num]=20, [ch]=#\- なら \"~20,,,'#\\-a\"
従って、これを書式とするformat式は (format nil \"~20,,,'#\\-a\" #\-)
となり[ch]が[num]個続く文字列が値となる。

[60]> (repeated-char-string 20 #\-)
\"--------------------\"
[61]> "
  (let (fmt result)
    ;;(setf fmt (format nil "~~~d,,,\'\~c\a" num ch ch)) ;; It's magic.
    (setf fmt (format nil "~~~d,,,\'\~c\a" num ch)) ;; It's a magic.
    (setf result (format nil fmt ch))
    (return-from repeated-char-string result)
    )
  )

(defun print-repeated-char-string (num ch)
  (format t "~a~%" (repeated-char-string num ch))
  (finish-output)
  )

(defun length-list (num)
  "0から(1- num)までの数値を要素とするリストを返す。
(length-list 6) ==> (0 1 2 3 4 5)"
  (let (result)
    (setq result nil)
    (dotimes (i num)
      (push i result)
      ) ;; end dotimes
    (return-from length-list (reverse result))
    ) ;; end let
  ) ;; end length-list

(defparameter *info-list* nil)

(defun record-quiz-info (&key ((:function-name fn-name) nil) ((:explanation exp) nil)
				((:position pos) nil) ((:candidate cand) nil))
  (let (a b c d)
    (cond
      ((identity fn-name)
       (setf (get '*info-list* 'function-name) fn-name)
       )
      ((identity exp)
       (setf (get '*info-list* 'explanation) exp)
       )
      ((identity pos)
       (setf (get '*info-list* 'position) pos)
       )
      ((identity cand)
       (setf (get '*info-list* 'candidate) cand)
       )
      ) ;; end cond
    (if (and
	 (setq a (get '*info-list* 'function-name))
	 (setq b (get '*info-list* 'explanation))
	 (setq c (get '*info-list* 'position))
	 (setq d (get '*info-list* 'candidate))
	 )
	(return-from record-quiz-info (list a b c d))
	(return-from record-quiz-info nil)
	) ;; end if
    )	  ;; end let
  ) ;; end record-quiz-info

(defun reset-record-quiz-info ()
  (setf (get '*info-list* 'function-name) nil)
  (setf (get '*info-list* 'explanation) nil)
  (setf (get '*info-list* 'position) nil)
  (setf (get '*info-list* 'candidate) nil)
  ) ;; end reset-record-quiz-info

(defun get-recorded-quiz-info ()
  (list (get '*info-list* 'function-name)
	(get '*info-list* 'explanation-name)
        (get '*info-list* 'position)
	(get '*info-list* 'candidate))
  ) ;; end get-recorded-quiz-info

#+clisp
(defun do-shell-command (command-string)
  (ext:shell command-string)
  ) ;; end do-shell-command

#+sbcl
(defun do-shell-command (command-str)
  (let (eos str)
    (setq eos (cons nil nil))
    (with-open-stream (s (do-shell-command-sub command-str))
      (loop
	(setq str (read-line s nil eos))
	(if (eq str eos) (return))
	(format t "~a~%" str)
	) ;; end loop
      )	  ;; end with-open-stream
    )	  ;; end let
  ) ;; end do-shell-command

(defparameter *shell* "bash")

#+:sbcl
(defun do-shell-command-sub (command-str)
  (sb-ext:process-output
   (sb-ext:run-program *shell* (list "-c" command-str) :input t :output :stream :search t :wait t)
   )
  )

(defun do-external-command (program &optional (opt nil) (in-file nil)
				      #+sbcl (out-file nil)
				      )
"sbclでは、次の式は動作するが \"cat\" を \"less\" あるいは \"more\" とするとエラーとなり動かない。
\"ls\"コマンドなども動く。未解決。

* (sb-ext:run-program \"cat\" (list \"sudoku-games-20240204.lisp\") :output t :search t)

debugger invoked on a SB-SYS:INTERACTIVE-INTERRUPT @7F4618D1A20F in thread..."
#+clisp
  (cond
    ((null opt)
     (ext:run-program program :input in-file)
     )
    (t
     (ext:run-program program :arguments opt :input in-file)
     )
    ) ;; end cond
#+sbcl
  (cond
    ((and
      (null opt)
      (null in-file)
      (null out-file)
      )
     (sb-ext:run-program program nil :input nil :output t :search t)
     )
    ((and
      (null opt)
      (identity in-file)
      (null out-file)
      )
     (sb-ext:run-program program nil :input in-file :output t :search t)
     )
    ((and
      (null opt)
      (null in-file)
      (identity out-file)
      )
     (sb-ext:run-program program nil :input nil :output out-file :search t)
     )
    ((and
      (null opt)
      (identity in-file)
      (identity out-file)
      )
     (sb-ext:run-program program nil :input in-file :output t :search t)
     )
    ((and
      (identity opt)
      (null in-file)
      (null out-file)
      )
     (sb-ext:run-program program (list opt) :input nil :output t :search t)
     )
    ((and
      (identity opt)
      (identity in-file)
      (null out-file)
      )
     (sb-ext:run-program program (list opt) :input in-file :output t :search t)
     )
    ((and
      (identity opt)
      (null in-file)
      (identity out-file)
      )
     (sb-ext:run-program program (list opt) :input nil :output out-file :search t)
     )
    ((and
      (identity opt)
      (identity in-file)
      (identity out-file)
      )
     (sb-ext:run-program program (list opt) :input in-file :output out-file :search t)
     )
    ) ;; end cond
#+(not (or clisp sbcl))
  (do-nothing)
  )

(defun external-less (fname)
  (do-shell-command (concatenate 'string "less" " " fname))
  )

(defun find-paps ()
"papsはutf-8テキストをPostScriptファイルに変換するコマンド。
pure-find-papsはpapsコマンドが環境変数[PATH]で検索可能な範囲に存在するか調べる。
存在すればパス名付きでpapsコマンドの名前を返す。検索可能な範囲に存在しなければ[nil]を返す。

paps  https://docs.oracle.com/cd/E75431_01/html/E71065/paps-1.html
Pango https://ja.wikipedia.org/wiki/Pango

多くのLinuxディストリビューションに含まれているが、インストール済みでないなら 
aptなどのパッケージ管理ソフトでインストールできる。パッケージ管理ソフトがaptの場合は

$ sudo apt install paps
"
  (if (eq *paps* 'not-checked-yet)
      (return-from find-paps (setq *paps* (pure-find-paps))) ;; 以降、*paps* は文字列型か[nil]。
      (return-from find-paps *paps*)
      ) ;; end if
  ) ;; end find-paps

(defun pure-find-paps ()
  "find-paps関数の実体。"
  (dolist (s (getenv-path-string-list))
    (if (probe-file (concatenate 'string s "/paps"))
	(return-from pure-find-paps (concatenate 'string s "/paps"))
	) ;; end if
    )	  ;; end dolist
  (print-colored-string 'red "Warning : paps command not found."
			:text-or-background 'background-color :use-terpri t)
  ;;(terpri)
  (format t " utf-8テキストをPostscriptファイルに変換するpapsコマンドが")
  (format t "環境変数PATHで検索可能な範囲に存在しません。~%")
  (format t "プリンタへの印刷用コマンドlprがutf-8に対応していないため、ひらがな・カタカナ・漢字が")
  (format t "印刷の際に文字化けします。文字化けを防ぐためにインストールをお薦めします(印刷自体は続行します)。~%")
  (format t "paps  https://docs.oracle.com/cd/E75431_01/html/E71065/paps-1.html~%")
  (format t "インストール方法は sudo apt install paps です。~%")
  (return-from pure-find-paps nil)
  ) ;; end find-paps

(defun external-lpr (fname)
  (let ((spc " ") paps)
    (setq paps (find-paps))
    (if (null paps)
	(do-shell-command (concatenate 'string *lpr* spc fname)) ;; papsなしで実行(漢字が化ける)。
	(do-shell-command (concatenate 'string paps spc fname spc "|" spc *lpr*))
	) ;; end if
    )	  ;; end let
  )

(defun use-external-less (&optional (size (* 80 25) sw))
"「長い」ヘルプメッセージを表示する際に外部コマンドの[less]を使う基準の「文字数」。"
  (cond
    ((null sw)
     *use-external-less*)
    (t
     (setf *use-external-less* size)
     )
    ) ;; end cond
  )

(defun getenv-string (name)
  "文字列[name]に一致する環境変数の値を文字列で返す。
(get-environment \"PATH\") ==>
\"/opt/local/bin:/opt/local/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/snap/bin\"
"
#+clisp (ext:getenv name)
#+sbcl  (sb-ext:posix-getenv name)
#+(not (or clisp sbcl)) (do-nothing)
  )

(defun getenv-path-string-list ()
  "環境変数[PATH]の値を\:毎に区切った文字列のリストとして返す。
> (getenv-path-string-list) ==>
(\"/opt/local/bin\" \"/opt/local/sbin\" \"/usr/local/sbin\" \"/usr/local/bin\" \"/usr/sbin\"
 \"/usr/bin\" \"/sbin\" \"/bin\" \"/usr/games\" \"/usr/local/games\" \"/snap/bin\" \"/snap/bin\")
"
  (let (env-string len pos str result)
    (setq env-string (getenv-string "PATH"))
    (setq result nil)
    (setq str nil)
    (setq pos 0)
    (setq len (length env-string))
    (loop
      (block getenv-block
	(when (= pos (1- len))
	  (push (format nil "~a" (char env-string pos)) str)
	  (push (pack-to-string (reverse str)) result)
	  (return)
	  ) ;; exit to this loop.
	(when (char= (char env-string pos) #\:)
	  (push (pack-to-string (reverse str)) result)
	  (incf pos)
	  (setq str nil)
	  (return-from getenv-block nil)
	  ) ;; end when
	(push (format nil "~a" (char env-string pos)) str)
	(incf pos)
	) ;; end block
      ) ;; end loop
    (return-from getenv-path-string-list (reverse result))
    ) ;; end let
  ) ;; end getenv-string-list

(defun multi-position-function-p (tesuji-function-name)
  (member tesuji-function-name *multi-position-function* :test #'equal)
  )

(defun need-working-board-function-p (tesuji-function-name)
  (member tesuji-function-name *need-working-board* :test #'equal)
  )

(defun update-board-every-game-p (tesuji-function-name)
  (member tesuji-function-name *update-board-every-game* :test #'equal)
  ) ;; end update-board-every-game-p

(defun update-every-game-p (tesuji-function-name)
  (or
   (need-working-board-function-p tesuji-function-name) ;; 解答するごとに盤面更新が必要な関数か？
   (update-board-every-game-p tesuji-function-name) ;; 解答するごとに盤面更新を望む関数か？
   )
  ) ;; end update-every-game-p

(defun manage-function-for-update-game
    (&key ((:add add-fnames) nil) ((:del del-fnames) nil) ((:set set-fnames) nil)
       ((:del-all del-all-p) nil) ((:add-all add-all-p) nil))
  "関数[guess-game]で解答するたびに盤面更新を行いたい関数を追加・削除する。
引数なしで呼び出すと、現在の設定値のリストを返す。

解答するたびに盤面更新が必要な関数は[*need-working-board*]に登録しておく。

追加・削除対象となるのは現在の[*permitted-methods*]の要素である手筋関数名だけ。
:del は現在の設定値[*update-board-every-game*]に含まれている手筋関数名だけを取り除く。
含まれていない手筋関数名については何もしない。

すべての手筋関数名を空にするばあいは
(manage-function-for-update-game :del-all t)

(manage-function-for-update-game :set nil)ではない。これは「設定するべき手筋関数名が空」という意味になる。

(manage-function-for-update-game :add 'do-nice-loop)
(manage-function-for-update-game :add '(do-nice-loop))
(manage-function-for-update-game :add '(do-fundamental do-nice-loop))

(manage-function-for-update-game :del 'do-nice-loop)
(manage-function-for-update-game :del '(do-nice-loop))
(manage-function-for-update-game :del '(do-fundamental do-nice-loop))

(manage-function-for-update-game :set 'do-nice-loop)
(manage-function-for-update-game :set '(do-n-tupes do-nice-loop))

(manage-function-for-update-game :del-all t)
(manage-function-for-update-game :add-all t)
"
  (cond
    ((and ;; 手筋関数名をひとつだけ追加する。
      (symbolp add-fnames)
      (member add-fnames *permitted-methods* :test #'equal)
      (not (member add-fnames *update-board-every-game* :test #'equal))
      )
     (push add-fnames *update-board-every-game*)
     )
    ((and ;; 複数の手筋関数名すべてをリスト形式で与えて追加する。
      (pure-listp add-fnames)
      (subsetp add-fnames *permitted-methods* :test #'equal)
      )
     (setq *update-board-every-game* (union *update-board-every-game* add-fnames :test #'equal))
     )
    ((and ;; 手筋関数名を現在の設定値から取り除く。現在の設定値に指定した手筋関数名が含まれていなければ何もしない。
      (symbolp del-fnames)
      (member del-fnames *permitted-methods* :test #'equal)
      (member del-fnames *update-board-every-game* :test #'equal)
      )
     (setq *update-board-every-game* (remove del-fnames *update-board-every-game* :test #'equal))
     )
    ((and
      ;; 指定したリストに含まれる手筋関数名を現在の設定値から取り除く。
      ;; 現在の設定値に含まれている手筋関数名を取り除く。含まれていない手筋関数名については何もしない。
      (pure-listp del-fnames)
      )
     (dolist (p del-fnames *update-board-every-game*)
       (if (member p *update-board-every-game* :test #'equal)
	   (setq *update-board-every-game* (remove p *update-board-every-game* :test #'equal))
	   ) ;; end if
       ) ;; end dolist
     )
    ((and ;; 現在の設定値を指定された手筋関数名に設定する。
      (symbolp set-fnames)
      (member set-fnames *permitted-methods* :test #'equal)
      )
     (setq *update-board-every-game* (list set-fnames))
     )
    ((pure-listp set-fnames)
     (when (null (intersection set-fnames *permitted-methods* :test #'equal))
       (warn "~aのすべての関数名は使用が許可された手筋関数名ではないため設定値は[nil]になります。~%"
	     set-fnames)
       (finish-output *error-output*)
       ) ;; end when
     (setq *update-board-every-game* (intersection set-fnames *permitted-methods* :test #'equal))
     )
    ((identity del-all-p) ;; 現在の設定値を空[nil]にする。
     (setq *update-board-every-game* nil)
     )
    ((identity add-all-p) ;; 現在の設定値を使用を許可した全ての手筋関数名にする。
     (setq *update-board-every-game* *permitted-methods*)
     )
    (t ;; いずれの条件も満たさないか、引数が指定されていなければ現在の設定値を返す。
     *update-board-every-game*
     )
    ) ;; end con
  ) ;; end manage-function-for-update-every-game

(defun make-prototype-document (source-file output-file
				&key ((:sort sort-p) nil) ((:comment comment-p) nil))
  "[source-file]で指定されたソースコードを読み込んで関数名と引数リスト、
そして、もしあれば関数ドキュメントを[output-file]に保存する。
[:sort]キーワードに[t]を指定すると関数名のアルファベット順に整列して出力する。
[:commentize]キーワードに[t]を指定すると各出力行の先頭に\";;\"を付加してCommon Lispのコメント行にする。"
  (let (exp function-name lambda-list function-document prototype-data eos)

    (when (null (probe-file source-file))
      (warn "処理すべき入力ファイルが存在しません。")
      (return-from make-prototype-document nil)
      ) ;; end when

    (setq eos (cons nil nil)) ;; end of stream marker.
    (setq prototype-data nil)
    (with-open-file (input-stream source-file :direction :input)
      (loop
	(setq exp (read input-stream nil eos))
	(if (eq exp eos)
	    (return) ;; exit this loop.
	    )
	(when (equal (first exp) 'defun)
	  (setq function-name (second exp))
	  (setq lambda-list (third exp))
	  (setq function-document (documentation function-name 'function))
	  (if (null function-document)
	      (setq function-document "[関数ドキュメントは設定されていません]")
	      ) ;; end if
	  (push (list function-name lambda-list function-document) prototype-data)
	  ;;(format output-stream "~a~%" (repeated-char-string 72 #\-))
	  ) ;; end when
	)   ;; end loop
      )     ;; end with-open-file

    (if sort-p
      (setq prototype-data
	    (sort (copy-seq prototype-data) #'(lambda (x y) (symbol-lessp (first x) (first y)))))
      (setq prototype-data (reverse prototype-data))
      ) ;; end if

    (with-open-file (output-stream output-file
				   :direction :output :if-does-not-exist :create :if-exists :supersede)
      (dolist (p prototype-data)
	(if comment-p (format output-stream ";;"))
	(format output-stream "~a~%" (repeated-char-string 72 #\-))
	(if comment-p (format output-stream ";;"))
	(format output-stream "\(defun ~a ~a ...\)~%" (first p) (second p))
	(if comment-p (format output-stream ";;"))
	(format output-stream "~a~%" (third p))
	) ;; end dolist
      (format output-stream "~a~%" (repeated-char-string 72 #\-))
      )	;; end with-open-file
    (return-from make-prototype-document (length prototype-data)) ;; 含まれていた関数定義の数を返す。
    )	      ;; end let
  ) ;; end make-prototype-document

(defun string-equal-by-name-p (str1 str2)
  (string-equal (symbol-name str1) (symbol-name str2))
  )

;;=================================================================================
(defun init-file-name (&optional (fname "NumberPlace-init.lisp"))
  (format nil "~a~a" (namestring (user-homedir-pathname)) fname))

(defun current-directory-pathname ()
  (truename *default-pathname-defaults*))

(defun current-directory-pathname-string ()
  (namestring (current-directory-pathname)))

(defun read-initial-settings (&optional (in-file (init-file-name)))
"NumberPlace.lispに対する初期設定用ファイルを読み込む。
もしホーム・ディレクトリに [init-file-name]というファイルがあれば
その内容を読み込んで評価する。もし指定されたファイルが存在しなければ何もしない。"
  (load in-file :if-does-not-exist nil) )

(read-initial-settings (init-file-name "NumberPlace-init.lisp")) ;; 初期設定用ファイルの自動読み込みを行う。
;;=================================================================================

;;;
;;; ここまで。以下のコードは主にデバッグ用。削除してもNumberPlace.lispの動作には影響しない。
;;;

;; top95の全データを読み込みリストとして返す。(setf top95-data (read-top95))などとする。
(defun read-top95 (&optional (top95-file (namestring (truename "top95.data"))))
  (read-chunk top95-file))

(defun test-top95 ()
  (let ((result nil) top95)
    (setf top95 (read-top95))
    (dotimes (i (length top95))
      (format t "~%問題 ~d~%" (1+ i))
      (stat (nth i top95))
      (push (exec-count) result)
      )
    (return-from test-top95 (reverse result)) ) )

(defun plot-top95 ()
  (let ((result nil) top95)
    (setf top95 (read-top95))
    (dotimes (i (length top95))
      (format t "~%問題 ~d~%" (1+ i))
      (plot (nth i top95))
      (push (exec-count) result)
      )
    (return-from plot-top95 (reverse result))))

;;; sample-board-1からsample-board-10を実行する。
;;; (time (benchmark))で合計実行時間も表示できる。
(defun benchmark (&optional (boards *sample-boards*))
  (let ((n 0))
    (save-env)
    (explanation-level 0)
    (dolist (i boards)
      (format t "~%問題 ~d~%" (incf n))
      (time (numberplace i)) )
    (restore-env)
    (return-from benchmark t) ))


;;; sample-board-1からsample-board-10を実行する。
(defun test-all (&optional (boards *sample-boards*))
  (let ((n 0))
    (dolist (i boards)
      (format t "~%問題 ~d~%" (incf n))
      (simple-answer i))))

;;; sample-board-1からsample-board-10をプロットする。
(defun plot-all (&optional (boards *sample-boards*))
  (let ((n 0))
    (dolist (i boards)
      (format t "~%問題 ~d~%" (incf n))
      (plot i))))

;;; sample-board-1からsample-board-10を大きなサイズで表示する。
(defun print-all (&optional (boards *sample-boards*))
  (let ((n 0))
    (dolist (i boards)
      (format t "問題 ~d~%" (incf n))
      (print-normal i))))

(defun test-gekikara9 ()
  (let ((result nil) gekikara9)
    (setf gekikara9 (read-chunk "nikoli-gekikara9-level-10.data"))
    (dotimes (i (length gekikara9))
      (format t "~%問題 ~d~%" (+ i 92))
      (stat (nth i gekikara9))
      (push (exec-count) result)
      )
    (return-from test-gekikara9 (reverse result))))

(defun plot-gekikara9 ()
  (let ((result nil) gekikara9)
    (setf gekikara9 (read-chunk "nikoli-gekikara9-level-10.data"))
    (dotimes (i (length gekikara9))
      (format t "~%問題 ~d~%" (+ i 92))
      (plot (nth i gekikara9))
      (push (exec-count) result)
      )
    (return-from plot-gekikara9 (reverse result))))

(defun test-marvin ()
  (let (marvin53 brd)
    (setf marvin53 (read-chunk "marvin53.data"))
    (format t "~s~%" (mapcar #'finished-p marvin53))
    (setf brd (new-board (first marvin53)))
    (dolist (p marvin53)
      (dotimes (i *board-size*)
        (dotimes (j *board-size*)
          (cond
            ((and (identity (aref brd i j)) (not (equal (aref brd i j) (aref p i j))))
             (setf (aref brd i j) nil))
            (t (do-nothing))))))
    (print-normal brd)))

(defun debug-sashimi ()
  (let (result gb-cells)
    (setf result nil)
    (setf gb-cells '( (0 0) (5 0) (0 3) (6 3) (2 8) (5 8) (6 8) ))
    (dotimes (i *board-size*)
      (dotimes (j *board-size*)
        (if (and
             (pure-listp (aref als-06 i j))
             (member 6 (aref als-06 i j)))
            (push (list i j) result)
            ) ;; end if
        ) ;; end dotimes
      ) ;; end dotimes
    (setf result (set-difference result gb-cells :test #'equal))
    (return-from debug-sashimi result)
    ) ;; end let
  )

(defun make-mini-board (cell-list &optional (str "*"))
  (let (mini-board)
    (setf mini-board (make-array (list *board-size* *board-size*) :initial-element nil))
    (if (null cell-list) (return-from make-mini-board mini-board))
    (dolist (p cell-list) (setf (aref mini-board (first p) (second p)) str))
    ;;(print-mini mini-board)
    (return-from make-mini-board mini-board)))

(defun print-cells (cells &optional (str "*"))
  (print-mini (make-mini-board cells str)))

(defun debug-do-almost-locked-set (brd)
  (depth 0)
  (print-check t)
  (capital-address nil)
  (explanation-level 10)
  (do-almost-locked-set brd)
  )

(defun save-apropos-data (fname)
  (let (stream)
    (finish-output *standard-output*)
    (setq stream *standard-output*)
    (with-open-file (s fname :direction :output :if-exists :overwrite :if-does-not-exist :create)
      (setq *standard-output* s)
      (apropos "" (find-package 'NumberPlace))
      (finish-output s)
      )
    (setq *standard-output* stream)
    (finish-output)
    ) ;; end let
  ) ;; end save-apropos-data

#|
#2A(((2 5 7) (5 6 7) (5 6 7) (1 4 5 6 7) 8 3 9 (2 4 5 6) (1 2 5))
    (1 (5 6 7 9) (5 6 7 8 9) (4 5 6 7 9) (2 4 6 9) (2 4 5 6 7) (4 5 6 8) 3 (2 5 8))
    ((2 3 5 8 9) (3 5 6 9) 4 (1 5 6 9) (1 2 6 9) (1 2 5 6) (1 5 6 8) 7 (1 2 5 8))
    ((5 7 8 9) 4 2 (1 5 6 8 9) 3 (1 5 6 8) (5 6 7 8) (5 6 8 9) (5 7 8 9))
    (6 (1 3 5 7 9) (1 3 5 7 8 9) (1 5 8 9) (1 2 9) (1 2 5 8) (3 5 7 8) (2 5 8 9) 4)
    ((3 5 8 9) (3 5 9) (3 5 8 9) (4 5 6 8 9) 7 (2 4 5 6 8) (3 5 6 8) 1 (2 3 5 8 9))
    ((3 4 5 7 9) 2 (1 3 5 6 7 9) (1 3 4 6 7 8) (1 4 6) (1 4 6 7 8) (1 3 4 5 7 8) (4 5 8 9) (1 3 5 7 8 9))
    ((3 4 5 7) 8 (1 3 5 6 7) (1 3 4 6 7) (1 4 6) 9 2 (4 5) (1 3 5 7))
    ((3 4 7 9) (1 3 7 9) (1 3 7 9) 2 5 (1 4 7 8) (1 3 4 7 8) (4 8 9) 6))
|#
(defun debug-print-colored-board ()
  (let (x cmode)
    (setf cmode (color-mode))
    (color-mode 2)
    (setf x (new-board (pm sample-board-6)))
    (format t "~s~%" x)
    (setf x (set-colored-candidate x '(4 2) 5 'red))
    (setf x (set-colored-candidate x '(4 2) 7 'yellow))
    (format t "~s~%" x)
    (setf x (set-colored-candidate x '(0 1) 5 'red))
    (setf x (set-colored-candidate x '(0 1) 7 'red))
    (format t "~s~%" x)
    (setf x (set-colored-cells x  '((blue (4 2) (5 0)) (green (4 5) (6 5)) (yellow (0 1)))))
    (format t "~s~%" x)
    (print-normal x)
    (show-color-board t)
    (teach als-01)
    (color-mode cmode)
    )
  )
;; EOF

(provide :NumberPlace)
