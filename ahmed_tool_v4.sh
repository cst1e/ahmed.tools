#!/bin/bash

# ==================================================
# 🎨 أداة أحمد لأدوات اختبار الاختراق (v4 - واجهة نصية محسنة)
# ✍️ تطوير: أحمد (تم التحديث بواسطة Manus)
# 📅 التاريخ: $(date +%Y-%m-%d)
# ⚠️ نسخة تجريبية - للاستخدام التعليمي فقط
# ==================================================

# --- تعريف الألوان والرموز (الصيغة الصحيحة لـ ANSI Escape Codes) ---
C_RESET='\e[0m'
C_BOLD='\e[1m'
C_DIM='\e[2m'
C_RED='\e[31m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_BLUE='\e[34m'
C_MAGENTA='\e[35m'
C_CYAN='\e[36m'
C_WHITE='\e[37m'

# خلفيات (اختياري)
BG_BLUE='\e[44m'
BG_MAGENTA='\e[45m'
BG_RED='\e[41m'
BG_YELLOW='\e[43m'

# رموز (تأكد من أن الطرفية تدعم UTF-8)
S_OK="${C_GREEN}✅${C_RESET}"
S_ERR="${C_RED}❌${C_RESET}"
S_WARN="${C_YELLOW}⚠️${C_RESET}"
S_INFO="${C_CYAN}ℹ️${C_RESET}"
S_PROMPT="${C_MAGENTA}▶${C_RESET}"
S_RETURN="${C_YELLOW}↩️${C_RESET}"
S_TOOL="${C_BLUE}🔧${C_RESET}"
S_CATEGORY="${C_MAGENTA}📁${C_RESET}"
S_EXIT="${C_RED}🚪${C_RESET}"

# ==================================================
# تنبيه هام وإخلاء مسؤولية (بتنسيق وألوان محسنة)
# ==================================================
echo -e "${C_BOLD}${BG_YELLOW}${C_RED}==================================================${C_RESET}"
echo -e "   ${S_WARN} ${C_BOLD}${C_RED}تنبيه هام وإخلاء مسؤولية${C_RESET} ${S_WARN}"
echo -e "${C_BOLD}${BG_YELLOW}${C_RED}==================================================${C_RESET}"
echo -e "${C_DIM}${C_WHITE}هذا السكربت \"أحمد\" مصمم للأغراض ${C_BOLD}${C_YELLOW}التعليمية والبحثية فقط${C_RESET}${C_DIM}${C_WHITE} في مجال الأمن السيبراني واختبار الاختراق الأخلاقي.${C_RESET}"
echo -e "${C_DIM}${C_WHITE}يُحظر تمامًا استخدام هذه الأداة في أي أنشطة ${C_BOLD}${C_RED}غير قانونية أو غير مصرح بها${C_RESET}${C_DIM}${C_WHITE}.${C_RESET}"
echo -e "${C_DIM}${C_WHITE}المطور (\"أحمد\") والمساهمون لا يتحملون أي مسؤولية عن أي استخدام غير قانوني أو ضار لهذه الأداة.${C_RESET}"
echo -e "${C_DIM}${C_WHITE}أنت وحدك المسؤول عن أفعالك وعن التأكد من امتثالك لجميع القوانين واللوائح المعمول بها قبل استخدام أي من الأدوات المدرجة.${C_RESET}"
echo -e "${C_BOLD}${C_RED}باستخدام هذا السكربت، فإنك توافق على هذه الشروط وتتحمل المسؤولية الكاملة عن استخدامك له.${C_RESET}"
echo -e "${C_BOLD}${BG_YELLOW}${C_RED}==================================================${C_RESET}"
read -p $"\t\t${C_GREEN}اضغط Enter للمتابعة...${C_RESET}"

# --- دوال مساعدة --- 

# دالة لطباعة فاصل مزخرف
print_separator() {
    echo -e "${C_BLUE}==================================================${C_RESET}"
}

# دالة لطباعة عنوان قسم
print_title() {
    print_separator
    echo -e "   ${C_BOLD}${C_MAGENTA}$1${C_RESET}"
    print_separator
}

# دالة لانتظار المستخدم
pause() {
    echo ""
    read -p $"${S_PROMPT} ${C_DIM}اضغط Enter للمتابعة...${C_RESET}"
}

# --- دوال الشبكة اللاسلكية --- 

# دالة لعرض الواجهات اللاسلكية وطلب اختيار واجهة
select_wifi_interface() {
    echo -e "${S_INFO} ${C_CYAN}الواجهات اللاسلكية المتاحة:${C_RESET}"
    local interfaces=$(iwconfig 2>/dev/null | grep '^[a-zA-Z]' | awk '{print $1}')
    if [ $? -ne 0 ] || [ -z "$interfaces" ]; then
        echo -e "${S_ERR} ${C_RED}لم يتم العثور على واجهات لاسلكية. تأكد من توصيل وتشغيل محول لاسلكي.${C_RESET}"
        return 1
    fi
    echo -e "${C_DIM}${interfaces}${C_RESET}" # عرض الواجهات بلون خافت
    local wifi_interface
    read -p $"${S_PROMPT} ${C_WHITE}أدخل اسم الواجهة اللاسلكية (e.g., wlan0): ${C_RESET}" wifi_interface
    # التحقق من وجود الواجهة
    if ! iwconfig $wifi_interface &> /dev/null; then
        echo -e "${S_ERR} ${C_RED}الواجهة '$wifi_interface' غير موجودة أو غير صحيحة.${C_RESET}"
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
        echo -e "${S_INFO} ${C_CYAN}وضع المراقبة مفعل بالفعل على ${C_BOLD}$monitor_interface${C_RESET}${C_CYAN}.${C_RESET}"
        echo $monitor_interface
        return 0
    fi
    echo -e "${S_INFO} ${C_YELLOW}محاولة تفعيل وضع المراقبة على ${C_BOLD}$interface${C_RESET}${C_YELLOW}...${C_RESET}"
    # إيقاف العمليات التي قد تتعارض (يتطلب sudo)
    sudo airmon-ng check kill > /dev/null 2>&1
    sleep 1
    sudo airmon-ng start $interface > /dev/null 2>&1
    sleep 2 # الانتظار قليلاً للتأكد من تفعيل الواجهة
    # التحقق مرة أخرى
    if iwconfig $monitor_interface &> /dev/null; then
        echo -e "${S_OK} ${C_GREEN}تم تفعيل وضع المراقبة بنجاح على ${C_BOLD}$monitor_interface${C_RESET}${C_GREEN}.${C_RESET}"
        echo $monitor_interface # إرجاع اسم واجهة المراقبة
        return 0
    else
        # محاولة اسم بديل (بعض الأنظمة تستخدم wlanXmon)
        monitor_interface="wlan${interface:4}mon"
         if iwconfig $monitor_interface &> /dev/null; then
            echo -e "${S_OK} ${C_GREEN}تم تفعيل وضع المراقبة بنجاح على ${C_BOLD}$monitor_interface${C_RESET}${C_GREEN}.${C_RESET}"
            echo $monitor_interface # إرجاع اسم واجهة المراقبة
            return 0
        else 
            echo -e "${S_ERR} ${C_RED}فشل تفعيل وضع المراقبة. حاول تشغيل السكربت بصلاحيات root (sudo).${C_RESET}"
            return 1
        fi
    fi
}

# دالة لإيقاف وضع المراقبة
stop_monitor_mode() {
    local monitor_interface=$1
    if [ -z "$monitor_interface" ]; then
        read -p $"${S_PROMPT} ${C_WHITE}أدخل اسم واجهة المراقبة لإيقافها (e.g., wlan0mon): ${C_RESET}" monitor_interface
        if [ -z "$monitor_interface" ]; then return 1; fi # User cancelled
    fi

    if iwconfig $monitor_interface &> /dev/null; then
        echo -e "${S_INFO} ${C_YELLOW}محاولة إيقاف وضع المراقبة على ${C_BOLD}$monitor_interface${C_RESET}${C_YELLOW}...${C_RESET}"
        sudo airmon-ng stop $monitor_interface > /dev/null 2>&1
        sleep 1
        # إعادة تشغيل NetworkManager إذا كان موجوداً (يتطلب sudo)
        if systemctl list-units --full -all | grep -q 'NetworkManager.service'; then
            sudo systemctl start NetworkManager > /dev/null 2>&1
        fi
        echo -e "${S_OK} ${C_GREEN}تم إيقاف وضع المراقبة.${C_RESET}"
    else
        echo -e "${S_INFO} ${C_CYAN}الواجهة ${C_BOLD}$monitor_interface${C_RESET}${C_CYAN} ليست في وضع المراقبة أو غير موجودة.${C_RESET}"
    fi
}

# --- القوائم والوظائف الرئيسية --- 

# دالة لعرض القائمة الرئيسية
show_main_menu() {
    clear
    # ASCII Art Header (AHMED)
    echo -e "${C_BOLD}${C_BLUE}"
    echo '    ___    __  __  ______  _____   ____     '
    echo '   /   |  / / / / / ____/ / /   | / __ \    '
    echo '  / /| | / / / / / __/   / / /| |/ / / /    '
    echo ' / ___ |/ /_/ / / /___  / / ___ / /_/ /     '
    echo '/_/  |_|\____/ /_____/ /_/_/  |_/_____/      '
    echo -e "          ${C_DIM}أداة أحمد لأدوات اختبار الاختراق ${C_MAGENTA}v4${C_RESET}"
    print_separator
    echo -e "   ${C_BOLD}${C_WHITE}--- اختر فئة الأدوات ---${C_RESET}   "
    echo -e "   ${S_CATEGORY} ${C_CYAN}1.${C_RESET} ${C_WHITE}جمع المعلومات ${C_DIM}(Information Gathering)${C_RESET}"
    echo -e "   ${S_CATEGORY} ${C_CYAN}2.${C_RESET} ${C_WHITE}تحليل الثغرات ${C_DIM}(Vulnerability Analysis)${C_RESET}"
    echo -e "   ${S_CATEGORY} ${C_CYAN}3.${C_RESET} ${C_WHITE}تحليل تطبيقات الويب ${C_DIM}(Web Application Analysis)${C_RESET}"
    echo -e "   ${S_CATEGORY} ${C_CYAN}4.${C_RESET} ${C_WHITE}هجمات كلمة المرور ${C_DIM}(Password Attacks)${C_RESET}"
    echo -e "   ${S_CATEGORY} ${C_CYAN}5.${C_RESET} ${C_WHITE}أدوات الاستغلال ${C_DIM}(Exploitation Tools)${C_RESET}"
    echo -e "   ${S_CATEGORY} ${C_CYAN}6.${C_RESET} ${C_WHITE}هجمات الشبكات اللاسلكية ${C_DIM}(Wireless Attacks)${C_RESET}"
    echo -e "   ${S_CATEGORY} ${C_CYAN}7.${C_RESET} ${C_WHITE}التنصت والخداع ${C_DIM}(Sniffing & Spoofing)${C_RESET}"
    echo -e "   ${S_EXIT} ${C_RED}8.${C_RESET} ${C_WHITE}خروج${C_RESET}"
    print_separator
    read -p $"${S_PROMPT} ${C_BOLD}${C_WHITE}اختر فئة [1-8]: ${C_RESET}" main_choice
}

# دالة لتشغيل أمر وعرض مخرجاته بشكل أفضل
run_command_pretty() {
    local title="$1"
    local cmd="$2"
    clear
    print_title "${S_TOOL} جارٍ تشغيل: $title"
    echo -e "${C_DIM}الأمر: $cmd${C_RESET}"
    print_separator
    # تنفيذ الأمر مباشرة في الطرفية
    eval $cmd
    print_separator
    pause # استخدام دالة pause المحسنة
}

# --- الحلقات الفرعية لكل قائمة --- 

# 1. جمع المعلومات
menu_info_gathering() {
    while true; do
        clear
        print_title "${S_CATEGORY} 1. جمع المعلومات"
        echo -e "   ${S_TOOL} ${C_CYAN}1)${C_RESET} ${C_WHITE}فحص الشبكة ${C_BOLD}${C_BLUE}(Nmap)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}2)${C_RESET} ${C_WHITE}جمع معلومات OSINT ${C_BOLD}${C_BLUE}(theHarvester)${C_RESET}"
        echo -e "   ${S_RETURN} ${C_YELLOW}3)${C_RESET} ${C_WHITE}رجوع للقائمة الرئيسية${C_RESET}"
        print_separator
        read -p $"${S_PROMPT} ${C_BOLD}${C_WHITE}اختر أداة [1-3]: ${C_RESET}" sub_choice
        case $sub_choice in
            1) read -p $"${S_PROMPT} ${C_WHITE}أدخل IP أو نطاق الهدف لـ ${C_BOLD}${C_BLUE}Nmap${C_RESET}: ${C_RESET}" target; 
               if [ -n "$target" ]; then run_command_pretty "Nmap Scan" "nmap -sV -A $target"; fi ;; 
            2) read -p $"${S_PROMPT} ${C_WHITE}أدخل اسم النطاق لـ ${C_BOLD}${C_BLUE}theHarvester${C_RESET}: ${C_RESET}" domain; 
               if [ -n "$domain" ]; then run_command_pretty "theHarvester Scan" "theHarvester -d $domain -l 500 -b all"; fi ;; 
            3) break ;; # رجوع
            *) echo -e "${S_ERR} ${C_RED}خيار غير صالح${C_RESET}"; sleep 1 ;; 
        esac
    done
}

# 2. تحليل الثغرات
menu_vuln_analysis() {
    while true; do
        clear
        print_title "${S_CATEGORY} 2. تحليل الثغرات"
        echo -e "   ${S_TOOL} ${C_CYAN}1)${C_RESET} ${C_WHITE}فحص ثغرات الويب ${C_BOLD}${C_BLUE}(Nikto)${C_RESET}"
        echo -e "   ${S_RETURN} ${C_YELLOW}2)${C_RESET} ${C_WHITE}رجوع للقائمة الرئيسية${C_RESET}"
        print_separator
        read -p $"${S_PROMPT} ${C_BOLD}${C_WHITE}اختر أداة [1-2]: ${C_RESET}" sub_choice
        case $sub_choice in
            1) read -p $"${S_PROMPT} ${C_WHITE}أدخل رابط الموقع (e.g., http://example.com) لـ ${C_BOLD}${C_BLUE}Nikto${C_RESET}: ${C_RESET}" url; 
               if [ -n "$url" ]; then run_command_pretty "Nikto Scan" "nikto -h $url"; fi ;; 
            2) break ;; # رجوع
            *) echo -e "${S_ERR} ${C_RED}خيار غير صالح${C_RESET}"; sleep 1 ;; 
        esac
    done
}

# 3. تحليل تطبيقات الويب
menu_web_app_analysis() {
    while true; do
        clear
        print_title "${S_CATEGORY} 3. تحليل تطبيقات الويب"
        echo -e "   ${S_TOOL} ${C_CYAN}1)${C_RESET} ${C_WHITE}تشغيل ${C_BOLD}${C_BLUE}Burp Suite${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}2)${C_RESET} ${C_WHITE}فحص حقن SQL ${C_BOLD}${C_BLUE}(SQLMap)${C_RESET}"
        echo -e "   ${S_RETURN} ${C_YELLOW}3)${C_RESET} ${C_WHITE}رجوع للقائمة الرئيسية${C_RESET}"
        print_separator
        read -p $"${S_PROMPT} ${C_BOLD}${C_WHITE}اختر أداة [1-3]: ${C_RESET}" sub_choice
        case $sub_choice in
            1) echo -e "${S_INFO} ${C_YELLOW}تشغيل ${C_BOLD}${C_BLUE}Burp Suite${C_RESET}${C_YELLOW} في الخلفية...${C_RESET}"; burpsuite & pause ;; 
            2) read -p $"${S_PROMPT} ${C_WHITE}أدخل رابط URL للفحص باستخدام ${C_BOLD}${C_BLUE}SQLMap${C_RESET}: ${C_RESET}" sql_url; 
               if [ -n "$sql_url" ]; then run_command_pretty "SQLMap Scan" "sqlmap -u \"$sql_url\" --batch --level=5 --risk=3"; fi ;; 
            3) break ;; # رجوع
            *) echo -e "${S_ERR} ${C_RED}خيار غير صالح${C_RESET}"; sleep 1 ;; 
        esac
    done
}

# 4. هجمات كلمة المرور
menu_password_attacks() {
    while true; do
        clear
        print_title "${S_CATEGORY} 4. هجمات كلمة المرور"
        echo -e "   ${S_TOOL} ${C_CYAN}1)${C_RESET} ${C_WHITE}كسر كلمات المرور ${C_BOLD}${C_BLUE}(John the Ripper)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}2)${C_RESET} ${C_WHITE}تخمين كلمات المرور أونلاين ${C_BOLD}${C_BLUE}(Hydra)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}3)${C_RESET} ${C_WHITE}إنشاء قوائم كلمات ${C_BOLD}${C_BLUE}(Crunch)${C_RESET}"
        echo -e "   ${S_RETURN} ${C_YELLOW}4)${C_RESET} ${C_WHITE}رجوع للقائمة الرئيسية${C_RESET}"
        print_separator
        read -p $"${S_PROMPT} ${C_BOLD}${C_WHITE}اختر أداة [1-4]: ${C_RESET}" sub_choice
        case $sub_choice in
            1) read -p $"${S_PROMPT} ${C_WHITE}أدخل مسار ملف الهاش لـ ${C_BOLD}${C_BLUE}John${C_RESET}: ${C_RESET}" hash_file; 
               if [ -n "$hash_file" ]; then run_command_pretty "John the Ripper" "john $hash_file"; fi ;; 
            2) echo -e "${S_INFO} ${C_DIM}مثال لاستخدام Hydra: hydra -L users.txt -P pass.txt ftp://192.168.1.1${C_RESET}"; 
               read -p $"${S_PROMPT} ${C_WHITE}أدخل أمر ${C_BOLD}${C_BLUE}Hydra${C_RESET} كاملاً: ${C_RESET}" hydra_cmd; 
               if [ -n "$hydra_cmd" ]; then run_command_pretty "Hydra Attack" "$hydra_cmd"; fi ;; 
            3) read -p $"${S_PROMPT} ${C_WHITE}أدخل الحد الأدنى لطول الكلمة لـ ${C_BOLD}${C_BLUE}Crunch${C_RESET}: ${C_RESET}" min; 
               read -p $"${S_PROMPT} ${C_WHITE}أدخل الحد الأقصى لطول الكلمة: ${C_RESET}" max; 
               read -p $"${S_PROMPT} ${C_WHITE}أدخل الأحرف المستخدمة (e.g., abcdef123): ${C_RESET}" chars; 
               read -p $"${S_PROMPT} ${C_WHITE}أدخل اسم ملف الإخراج: ${C_RESET}" outfile; 
               if [ -n "$min" ] && [ -n "$max" ] && [ -n "$chars" ] && [ -n "$outfile" ]; then 
                   run_command_pretty "Crunch Wordlist Generation" "crunch $min $max $chars -o $outfile"
                   echo -e "${S_OK} ${C_GREEN}تم إنشاء القائمة في ${C_BOLD}$outfile${C_RESET}${C_GREEN} (إذا نجح الأمر).${C_RESET}"
                   pause
               fi ;; 
            4) break ;; # رجوع
            *) echo -e "${S_ERR} ${C_RED}خيار غير صالح${C_RESET}"; sleep 1 ;; 
        esac
    done
}

# 5. أدوات الاستغلال
menu_exploitation_tools() {
    while true; do
        clear
        print_title "${S_CATEGORY} 5. أدوات الاستغلال"
        echo -e "   ${S_TOOL} ${C_CYAN}1)${C_RESET} ${C_WHITE}إنشاء بايلود ${C_BOLD}${C_BLUE}(MSFvenom)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}2)${C_RESET} ${C_WHITE}تشغيل ${C_BOLD}${C_BLUE}Metasploit Framework${C_RESET} ${C_DIM}(msfconsole)${C_RESET}"
        echo -e "   ${S_RETURN} ${C_YELLOW}3)${C_RESET} ${C_WHITE}رجوع للقائمة الرئيسية${C_RESET}"
        print_separator
        read -p $"${S_PROMPT} ${C_BOLD}${C_WHITE}اختر أداة [1-3]: ${C_RESET}" sub_choice
        case $sub_choice in
            1) 
                read -p $"${S_PROMPT} ${C_WHITE}أدخل نوع البايلود لـ ${C_BOLD}${C_BLUE}MSFvenom${C_RESET} (e.g., windows/meterpreter/reverse_tcp): ${C_RESET}" payload
                read -p $"${S_PROMPT} ${C_WHITE}أدخل LHOST (IP الخاص بك): ${C_RESET}" lhost
                read -p $"${S_PROMPT} ${C_WHITE}أدخل LPORT (e.g., 4444): ${C_RESET}" lport
                read -p $"${S_PROMPT} ${C_WHITE}أدخل صيغة الملف (e.g., exe, apk, elf, py): ${C_RESET}" format
                read -p $"${S_PROMPT} ${C_WHITE}أدخل اسم ملف الإخراج (e.g., payload.exe): ${C_RESET}" outfile
                if [ -n "$payload" ] && [ -n "$lhost" ] && [ -n "$lport" ] && [ -n "$format" ] && [ -n "$outfile" ]; then
                    run_command_pretty "MSFvenom Payload Generation" "msfvenom -p $payload LHOST=$lhost LPORT=$lport -f $format -o $outfile"
                    echo -e "${S_OK} ${C_GREEN}تم إنشاء البايلود: ${C_BOLD}$outfile${C_RESET}${C_GREEN} (إذا نجح الأمر).${C_RESET}"
                    pause
                fi ;; 
            2) run_command_pretty "Metasploit Framework" "msfconsole" ;; 
            3) break ;; # رجوع
            *) echo -e "${S_ERR} ${C_RED}خيار غير صالح${C_RESET}"; sleep 1 ;; 
        esac
    done
}

# 6. هجمات الشبكات اللاسلكية
menu_wireless_attacks() {
    local current_monitor_interface=""
    while true; do
        clear
        print_title "${S_CATEGORY} 6. هجمات الشبكات اللاسلكية"
        local mon_status_color=$C_RED
        local mon_status_text="غير مفعل"
        if [ -n "$current_monitor_interface" ]; then
            mon_status_color=$C_GREEN
            mon_status_text="${C_BOLD}$current_monitor_interface${C_RESET}${C_GREEN}"
        fi
        echo -e "   ${S_INFO} ${C_WHITE}الواجهة في وضع المراقبة حالياً: ${mon_status_color}${mon_status_text}${C_RESET}"
        print_separator
        echo -e "   ${S_TOOL} ${C_CYAN}1)${C_RESET} ${C_WHITE}اختيار واجهة وتفعيل وضع المراقبة ${C_BOLD}${C_BLUE}(Airmon-ng)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}2)${C_RESET} ${C_WHITE}فحص الشبكات المجاورة ${C_BOLD}${C_BLUE}(Airodump-ng)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}3)${C_RESET} ${C_WHITE}التقاط Handshake ${C_BOLD}${C_BLUE}(Airodump-ng)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}4)${C_RESET} ${C_WHITE}هجوم Deauthentication ${C_BOLD}${C_BLUE}(Aireplay-ng)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}5)${C_RESET} ${C_WHITE}كسر كلمة مرور WPA/WPA2 ${C_BOLD}${C_BLUE}(Aircrack-ng)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}6)${C_RESET} ${C_WHITE}فحص شبكات WPS ${C_BOLD}${C_BLUE}(Wash)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}7)${C_RESET} ${C_WHITE}هجوم WPS PIN ${C_BOLD}${C_BLUE}(Reaver)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_YELLOW}8)${C_RESET} ${C_WHITE}إيقاف وضع المراقبة${C_RESET}"
        echo -e "   ${S_RETURN} ${C_YELLOW}9)${C_RESET} ${C_WHITE}رجوع للقائمة الرئيسية${C_RESET}"
        print_separator
        read -p $"${S_PROMPT} ${C_BOLD}${C_WHITE}اختر أداة أو إجراء [1-9]: ${C_RESET}" sub_choice

        case $sub_choice in
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
                pause
                ;; 
            2) 
                if [ -z "$current_monitor_interface" ]; then echo -e "${S_WARN} ${C_YELLOW}يرجى تفعيل وضع المراقبة أولاً (الخيار 1).${C_RESET}"; pause; continue; fi
                echo -e "${S_INFO} ${C_CYAN}بدء فحص الشبكات على ${C_BOLD}$current_monitor_interface${C_RESET}${C_CYAN}... اضغط Ctrl+C للإيقاف.${C_RESET}"
                # تشغيل airodump في نافذة جديدة إذا أمكن، أو مباشرة
                if command -v xterm &> /dev/null; then
                   xterm -hold -e "sudo airodump-ng $current_monitor_interface" &
                   pause
                else
                   run_command_pretty "Airodump-ng Scan" "sudo airodump-ng $current_monitor_interface"
                fi
                ;; 
            3) 
                if [ -z "$current_monitor_interface" ]; then echo -e "${S_WARN} ${C_YELLOW}يرجى تفعيل وضع المراقبة أولاً (الخيار 1).${C_RESET}"; pause; continue; fi
                read -p $"${S_PROMPT} ${C_WHITE}أدخل BSSID للشبكة المستهدفة: ${C_RESET}" target_bssid
                read -p $"${S_PROMPT} ${C_WHITE}أدخل قناة الشبكة المستهدفة: ${C_RESET}" target_channel
                read -p $"${S_PROMPT} ${C_WHITE}أدخل اسم ملف الالتقاط (بدون امتداد): ${C_RESET}" capture_file
                if [ -n "$target_bssid" ] && [ -n "$target_channel" ] && [ -n "$capture_file" ]; then
                    echo -e "${S_INFO} ${C_CYAN}بدء التقاط الحزم على القناة ${C_BOLD}$target_channel${C_RESET}${C_CYAN} للشبكة ${C_BOLD}$target_bssid${C_RESET}${C_CYAN}... احفظ الملف باسم ${C_BOLD}$capture_file${C_RESET}${C_CYAN}. اضغط Ctrl+C للإيقاف بعد التقاط Handshake.${C_RESET}"
                    echo -e "${S_INFO} ${C_DIM}يمكنك استخدام الخيار 4 (Deauth) لتسريع الحصول على Handshake.${C_RESET}"
                    if command -v xterm &> /dev/null; then
                        xterm -hold -e "sudo airodump-ng --bssid $target_bssid -c $target_channel -w $capture_file $current_monitor_interface" &
                        pause
                    else
                        run_command_pretty "Airodump-ng Capture" "sudo airodump-ng --bssid $target_bssid -c $target_channel -w $capture_file $current_monitor_interface"
                    fi
                else
                    echo -e "${S_ERR} ${C_RED}إدخال غير كامل.${C_RESET}"
                    sleep 1
                fi
                ;; 
            4) 
                if [ -z "$current_monitor_interface" ]; then echo -e "${S_WARN} ${C_YELLOW}يرجى تفعيل وضع المراقبة أولاً (الخيار 1).${C_RESET}"; pause; continue; fi
                read -p $"${S_PROMPT} ${C_WHITE}أدخل BSSID للشبكة المستهدفة: ${C_RESET}" target_bssid
                read -p $"${S_PROMPT} ${C_WHITE}(اختياري) أدخل MAC للعميل المستهدف (اتركه فارغاً لاستهداف الجميع): ${C_RESET}" target_client_mac
                if [ -n "$target_bssid" ]; then
                    local attack_cmd="sudo aireplay-ng --deauth 0 -a $target_bssid"
                    if [ ! -z "$target_client_mac" ]; then
                        attack_cmd="$attack_cmd -c $target_client_mac"
                    fi
                    attack_cmd="$attack_cmd $current_monitor_interface"
                    echo -e "${S_INFO} ${C_YELLOW}بدء هجوم Deauthentication... اضغط Ctrl+C للإيقاف.${C_RESET}"
                    run_command_pretty "Aireplay-ng Deauth" "$attack_cmd"
                else
                    echo -e "${S_ERR} ${C_RED}يجب إدخال BSSID.${C_RESET}"
                    sleep 1
                fi
                ;; 
            5) 
                read -p $"${S_PROMPT} ${C_WHITE}أدخل مسار ملف الالتقاط (.cap) الذي يحتوي على Handshake: ${C_RESET}" capture_file_path
                read -p $"${S_PROMPT} ${C_WHITE}أدخل مسار قائمة الكلمات (Wordlist): ${C_RESET}" wordlist_path
                if [ ! -f "$capture_file_path" ]; then echo -e "${S_ERR} ${C_RED}ملف الالتقاط غير موجود.${C_RESET}"; pause; continue; fi
                if [ ! -f "$wordlist_path" ]; then echo -e "${S_ERR} ${C_RED}ملف قائمة الكلمات غير موجود.${C_RESET}"; pause; continue; fi
                echo -e "${S_INFO} ${C_YELLOW}بدء محاولة كسر كلمة المرور باستخدام ${C_BOLD}${C_BLUE}Aircrack-ng${C_RESET}${C_YELLOW}...${C_RESET}"
                run_command_pretty "Aircrack-ng Attack" "sudo aircrack-ng $capture_file_path -w $wordlist_path"
                ;; 
            6) 
                if [ -z "$current_monitor_interface" ]; then echo -e "${S_WARN} ${C_YELLOW}يرجى تفعيل وضع المراقبة أولاً (الخيار 1).${C_RESET}"; pause; continue; fi
                echo -e "${S_INFO} ${C_CYAN}بدء فحص شبكات WPS المجاورة باستخدام ${C_BOLD}${C_BLUE}Wash${C_RESET}${C_CYAN}... اضغط Ctrl+C للإيقاف.${C_RESET}"
                run_command_pretty "Wash WPS Scan" "sudo wash -i $current_monitor_interface"
                ;; 
            7) 
                if [ -z "$current_monitor_interface" ]; then echo -e "${S_WARN} ${C_YELLOW}يرجى تفعيل وضع المراقبة أولاً (الخيار 1).${C_RESET}"; pause; continue; fi
                read -p $"${S_PROMPT} ${C_WHITE}أدخل BSSID للشبكة المستهدفة (يجب أن تدعم WPS) لـ ${C_BOLD}${C_BLUE}Reaver${C_RESET}: ${C_RESET}" target_bssid
                if [ -n "$target_bssid" ]; then
                    echo -e "${S_INFO} ${C_YELLOW}بدء هجوم WPS PIN باستخدام ${C_BOLD}${C_BLUE}Reaver${C_RESET}${C_YELLOW} على ${C_BOLD}$target_bssid${C_RESET}${C_YELLOW}... قد يستغرق وقتاً طويلاً. اضغط Ctrl+C للإيقاف.${C_RESET}"
                    run_command_pretty "Reaver WPS Attack" "sudo reaver -i $current_monitor_interface -b $target_bssid -vv"
                else
                    echo -e "${S_ERR} ${C_RED}يجب إدخال BSSID.${C_RESET}"
                    sleep 1
                fi
                ;; 
            8) 
                if [ -n "$current_monitor_interface" ]; then
                    stop_monitor_mode $current_monitor_interface
                    current_monitor_interface=""
                else
                    echo -e "${S_INFO} ${C_CYAN}لا يوجد وضع مراقبة مفعل حالياً.${C_RESET}"
                fi
                pause
                ;; 
            9) 
                # التأكد من إيقاف وضع المراقبة قبل الخروج من القائمة الفرعية
                if [ -n "$current_monitor_interface" ]; then
                   echo -e "${S_WARN} ${C_YELLOW}لا تزال واجهة المراقبة (${C_BOLD}$current_monitor_interface${C_RESET}${C_YELLOW}) مفعلة.${C_RESET}"
                   read -p $"${S_PROMPT} ${C_WHITE}هل تريد إيقافها قبل الرجوع؟ (y/n): ${C_RESET}" confirm_stop
                   if [[ "$confirm_stop" == "y" || "$confirm_stop" == "Y" ]]; then
                       stop_monitor_mode $current_monitor_interface
                       current_monitor_interface=""
                   fi
                fi
                break ;; # الخروج من حلقة قائمة الواي فاي
            *) echo -e "${S_ERR} ${C_RED}خيار غير صالح${C_RESET}"; sleep 1 ;; 
        esac
    done
}

# 7. التنصت والخداع
menu_sniffing_spoofing() {
    while true; do
        clear
        print_title "${S_CATEGORY} 7. التنصت والخداع"
        echo -e "   ${S_TOOL} ${C_CYAN}1)${C_RESET} ${C_WHITE}تشغيل ${C_BOLD}${C_BLUE}Wireshark${C_RESET} ${C_DIM}(تحليل الحزم)${C_RESET}"
        echo -e "   ${S_TOOL} ${C_CYAN}2)${C_RESET} ${C_WHITE}تشغيل ${C_BOLD}${C_BLUE}Ettercap${C_RESET} ${C_DIM}(رسومي - MITM)${C_RESET}"
        echo -e "   ${S_RETURN} ${C_YELLOW}3)${C_RESET} ${C_WHITE}رجوع للقائمة الرئيسية${C_RESET}"
        print_separator
        read -p $"${S_PROMPT} ${C_BOLD}${C_WHITE}اختر أداة [1-3]: ${C_RESET}" sub_choice
        case $sub_choice in
            1) echo -e "${S_INFO} ${C_YELLOW}تشغيل ${C_BOLD}${C_BLUE}Wireshark${C_RESET}${C_YELLOW}...${C_RESET}"; sudo wireshark & pause ;; 
            2) echo -e "${S_INFO} ${C_YELLOW}تشغيل ${C_BOLD}${C_BLUE}Ettercap${C_RESET}${C_YELLOW} بواجهة رسومية...${C_RESET}"; sudo ettercap -G & pause ;; 
            3) break ;; # رجوع
            *) echo -e "${S_ERR} ${C_RED}خيار غير صالح${C_RESET}"; sleep 1 ;; 
        esac
    done
}

# --- الحلقة الرئيسية للبرنامج ---
while true; do
    show_main_menu

    case $main_choice in
        1) menu_info_gathering ;; 
        2) menu_vuln_analysis ;; 
        3) menu_web_app_analysis ;; 
        4) menu_password_attacks ;; 
        5) menu_exploitation_tools ;; 
        6) menu_wireless_attacks ;; 
        7) menu_sniffing_spoofing ;; 
        8) # خروج
            print_separator
            echo -e "   ${S_OK} ${C_GREEN}شكراً لاستخدامك أداة أحمد!${C_RESET}"
            echo -e "   ${S_WARN} ${C_YELLOW}تذكر: استخدمها بمسؤولية وللأغراض التعليمية فقط.${C_RESET}"
            print_separator
            exit 0
            ;;
        *) # خيار غير صالح
            echo -e "${S_ERR} ${C_RED}خيار غير صالح، يرجى الاختيار من 1 إلى 8.${C_RESET}"
            sleep 1.5
            ;;
    esac
done

