% --- استيراد المكتبات اللازمة ---
:- use_module(library(http/thread_httpd)). % لإنشاء خادم HTTP
:- use_module(library(http/http_dispatch)). % لتوجيه الطلبات
:- use_module(library(http/http_json)).    % لمعالجة JSON
:- use_module(library(http/http_cors)).  % للسماح بالطلبات من نطاقات مختلفة (مهم للواجهة الأمامية)

% --- قاعدة المعraseñaرفة لتشخيص أعطال السيارات (من الجزء الأول) ---
% (ابق على نفس كود قاعدة المعرفة الذي أنشأته في الخطوة السابقة هنا)
possible_cause(battery_dead, 'البطارية فارغة أو تالفة').
possible_cause(fuel_empty, 'نفاد الوقود').
possible_cause(spark_plugs_bad, 'شمعات الإشعال (البواجي) تالفة').

solution(battery_dead, 'قم بشحن البطارية أو فحصها واحتمال استبدالها.').
solution(fuel_empty, 'قم بتزويد السيارة بالوقود.').
solution(spark_plugs_bad, 'قم بفحص شمعات الإشعال واستبدلها إذا لزم الأمر.').

diagnose(Symptoms, CauseDesc, SolDesc) :-
    member(engine_does_not_start, Symptoms),
    member(lights_are_weak_or_off, Symptoms),
    possible_cause(battery_dead, CauseDesc),
    solution(battery_dead, SolDesc).

diagnose(Symptoms, CauseDesc, SolDesc) :-
    member(engine_does_not_start, Symptoms),
    member(engine_cranks_normally, Symptoms),
    member(fuel_gauge_shows_empty, Symptoms),
    possible_cause(fuel_empty, CauseDesc),
    solution(fuel_empty, SolDesc).

diagnose(Symptoms, CauseDesc, SolDesc) :-
    member(engine_misfires, Symptoms),
    member(check_engine_light_on, Symptoms),
    possible_cause(spark_plugs_bad, CauseDesc),
    solution(spark_plugs_bad, SolDesc).

diagnose(_, 'عذرًا، لم أتمكن من تحديد المشكلة بناءً على الأعراض المعطاة.', 'يرجى مراجعة ميكانيكي متخصص أو تقديم أعراض أكثر تفصيلاً.').
% --- نهاية قاعدة المعرفة ---


% --- تعريف معالج الطلبات لمسار /diagnose ---
% هذا المعالج سيستقبل طلبات POST التي تحتوي على الأعراض بصيغة JSON
:- http_handler('/diagnose', handle_diagnose_request, [method(post)]).

handle_diagnose_request(Request) :-
    % قراءة البيانات الـ JSON من جسم الطلب
    http_read_json_dict(Request,SymptomsJSON),
    % SymptomsJSON سيكون بصيغة: _{symptoms: ["symptom1", "symptom2"]}
    % نحتاج إلى استخلاص قائمة الأعراض الفعلية (كقائمة من الذرات - atoms)
    (   atom_terms(SymptomsJSON.symptoms, SymptomsList) % SymptomsJSON.symptoms يجب أن تكون قائمة من النصوص
    ->  (   % استدعاء قاعدة التشخيص الخاصة بنا
            diagnose(SymptomsList, Cause, Solution),
            % إعداد الرد بصيغة JSON
            Reply = _{cause: Cause, solution: Solution},
            reply_json_dict(Reply)
        )
    ;   % إذا كان تنسيق الـ JSON غير صحيح
        bad_request('تأكد من إرسال قائمة الأعراض في حقل "symptoms" ضمن كائن JSON.')
    ).

% لتحويل قائمة النصوص من JSON إلى قائمة ذرات (atoms) يتوقعها محرك برولوج
atom_terms([], []).
atom_terms([H_text|T_text], [H_atom|T_atom]) :-
    atom_string(H_atom, H_text), % يحول النص إلى ذرة
    atom_terms(T_text, T_atom).

% مساعدة للردود الخاطئة
bad_request(Message) :-
    reply_json_dict(_{error: Message}, [status(400)]).


% --- بدء الخادم ---
% يمكنك اختيار أي رقم منفذ (port) غير مستخدم، 8000 هو مثال شائع
server(Port) :-
    http_server(http_dispatch, [port(Port)]).

% لتمكين CORS (Cross-Origin Resource Sharing) للسماح لصفحة الويب بالتحدث إلى الخادم
% هذا مهم جدًا إذا كانت صفحة الويب والخادم على منافذ أو نطاقات مختلفة
:- set_setting(http:cors, ['*']). % يسمح بالوصول من أي مصدر، كن أكثر تحديدًا في الإنتاج

% --- لبدء الخادم تلقائيًا عند تحميل الملف (اختياري) ---
% :- initialization(server(8000)).
% يمكنك إلغاء التعليق عن السطر أعلاه إذا أردت أن يبدأ الخادم بمجرد تحميل الملف
% أو يمكنك بدءه يدويًا بعد التحميل عن طريق كتابة: server(8000).










