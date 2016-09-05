import org.hyperic.hq.hqu.rendit.HQUPlugin

import GooglemapController

class Plugin extends HQUPlugin {
	Plugin() {
		addAdminView(true, '/googlemap/index.hqu', 'Google Map')
    }         
}


