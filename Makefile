VERSION= 1.0a
PKG= luasoap-$(VERSION)
TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip
SRCS= README Makefile \
	soap.lua soap.http.lua test.lua \
	index.html manual.html license.html luasoap.png

dist:
	mkdir $(PKG)
	cp $(SRCS) $(PKG)
	tar -czf $(TAR_FILE) $(PKG)
	zip -lq $(ZIP_FILE) $(PKG)
	rm -rf $(PKG)

clean:
	rm $(TAR_FILE) $(ZIP_FILE)
