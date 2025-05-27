from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import os
import time
from playsound import playsound

# Nastavení Geckodriveru
options = Options()
#options.add_argument("--headless")  # Volitelné: spuštění bez otevření okna
service = Service("C:/Users/BIKEMAX/Downloads/geckodriver.exe")  # Zadejte správnou cestu k Geckodriveru
driver = webdriver.Firefox(service=service, options=options)

def upozornit():
    os.system("powercfg -change monitor-timeout-ac 0")  # Zapne obrazovku (widnows)
    playsound("Dobre_rano_curaci.mp3")  # Spustí zvuk

# Seznam specifických dnů
povolene_dny = {"July 30", "July 31", "August 1", "August 2", "August 3", "August 4", "August 5", "August 6"}

def kontrolovat_terminy():
    driver = webdriver.Firefox(service=service, options=options)
    volna_mista = []

    try:
        # Otevření webové stránky
        driver.get("https://www.westcoasttrail.app/permits/")
        time.sleep(5)

        # Vyhledání všech prvků s třídou "calendar-cell"
        elements = driver.find_elements(By.CLASS_NAME, "calendar-cell")

        for element in elements:
            bg_color = element.value_of_css_property("background-color")
            if bg_color == "rgb(0, 128, 0)":  # Zelená barva (RGB)
                # Najít nejbližší nadřazený <h2>
                parent = element.find_element(By.XPATH, "./ancestor::table//preceding::h2[1]")
                month = parent.text if parent else "Neznámý měsíc"
                day = element.text.strip()

                full_date = f"{month} {day}"
                if full_date in povolene_dny:
                    volna_mista.append(full_date)

        if volna_mista:
            print("Volné místo:", ", ".join(volna_mista))
        else:
            print("Žádný volný termín.")

    finally:
        driver.quit()  # Ukončení prohlížeče
# Nekonečná smyčka pro opakovanou kontrolu každých 31 minut
while True:
    volna_mista = kontrolovat_terminy()
    
    if volna_mista:
        upozornit()
    
    time.sleep(31 * 60)  # Počkej 31 minut

