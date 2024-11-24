from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from myproject import views


router = DefaultRouter()
router.register(r'devices', views.DeviceViewSet, basename='device')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    path('api/auth/register/', views.register_user),
    path('api/auth/login/', views.login_user),
    path('api/auth/devices/data/', views.upload_device_data),
    path('api/devices/<str:device_id>/<str:device_name>/locations/', views.get_device_locations),
    path('api/auth/devices/', views.get_devices),
    path('api/auth/register/', views.register_user),
    path('api/auth/devices/add/', views.add_device),
    path('api/devices/<str:device_id>/trigger-audio/', views.trigger_audio),
]
