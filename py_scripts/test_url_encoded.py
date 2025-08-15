

###########

3 отдельных блока для смены user пароль и исключения
1 для вывода всего результата

#Вбить учетку:
proxy_user
#Вбить пароль:
$proxy_pass
urllib.parse.quote($proxy_pass)
#Исключения прокси
$proxy_uns

http_proxy=http://$proxy_user:$proxy_pass@i.tatar.ru:8080
https_proxy=http://$proxy_user:$proxy_pass@i.tatar.ru:8080
ftp_proxy=http://$proxy_user:$proxy_pass@i.tatar.ru:8080
no_proxy=$proxy_uns

#Сразу чекаем вывод
#Уведомить что нужен ребут


#############

proxy_user, proxy_pass, proxy_uns = ''

#Меняем пароль VNC

input_text = self.http_input.get_text().strip()
input_text = self.https_input.get_text().strip()
input_text = self.no_proxy_input.get_text().strip()

    def on_save_button_clicked(self, button):
        input_text = self.ftp_input.get_text().strip()