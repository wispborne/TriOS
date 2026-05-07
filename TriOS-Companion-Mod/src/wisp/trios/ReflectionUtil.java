package wisp.trios;

import org.apache.log4j.Logger;

import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.util.ArrayList;
import java.util.List;

/**
 * MethodHandle-based reflection bypass for Starsector's classloader restrictions.
 * Technique adapted from MagicLib's ReflectionUtils (LGPL-3.0, credit Starficz, Lukas04, Lyravega, Float, Andylizi).
 */
public class ReflectionUtil {

    private static final MethodHandle getDeclaredFields;
    private static final MethodHandle getFieldType;
    private static final MethodHandle getFieldName;
    private static final MethodHandle getFieldValue;
    private static final MethodHandle setAccessible;
    private static final MethodHandle getDeclaredMethods;
    private static final MethodHandle getMethodName;
    private static final MethodHandle getReturnType;
    private static final MethodHandle getParameterCount;
    private static final MethodHandle invokeMethod;

    static {
        try {
            ClassLoader bootstrap = Class.class.getClassLoader();
            Class<?> fieldClass = Class.forName("java.lang.reflect.Field", false, bootstrap);
            Class<?> methodClass = Class.forName("java.lang.reflect.Method", false, bootstrap);
            Class<?> accessibleClass = Class.forName("java.lang.reflect.AccessibleObject", false, bootstrap);

            MethodHandles.Lookup lookup = MethodHandles.lookup();

            getDeclaredFields = lookup.findVirtual(Class.class, "getDeclaredFields",
                    MethodType.methodType(fieldClass.arrayType()));
            getFieldType = lookup.findVirtual(fieldClass, "getType",
                    MethodType.methodType(Class.class));
            getFieldName = lookup.findVirtual(fieldClass, "getName",
                    MethodType.methodType(String.class));
            getFieldValue = lookup.findVirtual(fieldClass, "get",
                    MethodType.methodType(Object.class, Object.class));
            setAccessible = lookup.findVirtual(accessibleClass, "setAccessible",
                    MethodType.methodType(void.class, boolean.class));

            getDeclaredMethods = lookup.findVirtual(Class.class, "getDeclaredMethods",
                    MethodType.methodType(methodClass.arrayType()));
            getMethodName = lookup.findVirtual(methodClass, "getName",
                    MethodType.methodType(String.class));
            getReturnType = lookup.findVirtual(methodClass, "getReturnType",
                    MethodType.methodType(Class.class));
            getParameterCount = lookup.findVirtual(methodClass, "getParameterCount",
                    MethodType.methodType(int.class));
            invokeMethod = lookup.findVirtual(methodClass, "invoke",
                    MethodType.methodType(Object.class, Object.class, Object[].class));
        } catch (Exception e) {
            throw new RuntimeException("Failed to initialize ReflectionUtil", e);
        }
    }

    public static Object getFieldValueByType(Object instance, Class<?> fieldType) throws Throwable {
        Class<?> clazz = instance.getClass();
        while (clazz != null && !clazz.getName().equals("java.lang.Object")) {
            Object[] fields = (Object[]) getDeclaredFields.invoke(clazz);
            for (Object field : fields) {
                Class<?> type = (Class<?>) getFieldType.invoke(field);
                if (fieldType.isAssignableFrom(type)) {
                    setAccessible.invoke(field, true);
                    return getFieldValue.invoke(field, instance);
                }
            }
            clazz = clazz.getSuperclass();
        }
        return null;
    }

    /**
     * Find a field by the simple name of its type (e.g. "TextureLoader"), walking the full class hierarchy.
     * Use this when the field's type is in a game JAR not visible to our classloader.
     */
    public static Object getFieldValueByTypeName(Object instance, String simpleTypeName) throws Throwable {
        Class<?> clazz = instance.getClass();
        while (clazz != null && !clazz.getName().equals("java.lang.Object")) {
            Object[] fields = (Object[]) getDeclaredFields.invoke(clazz);
            for (Object field : fields) {
                Class<?> type = (Class<?>) getFieldType.invoke(field);
                if (type.getSimpleName().equals(simpleTypeName)) {
                    setAccessible.invoke(field, true);
                    return getFieldValue.invoke(field, instance);
                }
            }
            clazz = clazz.getSuperclass();
        }
        return null;
    }

    /** Fallback: match if the type's simple name *contains* the given string (handles obfuscated-but-predictable names). */
    public static Object getFieldValueByTypeNameContains(Object instance, String typeNameSubstring) throws Throwable {
        Class<?> clazz = instance.getClass();
        while (clazz != null && !clazz.getName().equals("java.lang.Object")) {
            Object[] fields = (Object[]) getDeclaredFields.invoke(clazz);
            for (Object field : fields) {
                Class<?> type = (Class<?>) getFieldType.invoke(field);
                if (type.getName().contains(typeNameSubstring)) {
                    setAccessible.invoke(field, true);
                    return getFieldValue.invoke(field, instance);
                }
            }
            clazz = clazz.getSuperclass();
        }
        return null;
    }

    public static Object getStaticFieldValueByType(Class<?> clazz, Class<?> fieldType) throws Throwable {
        Object[] fields = (Object[]) getDeclaredFields.invoke(clazz);
        for (Object field : fields) {
            Class<?> type = (Class<?>) getFieldType.invoke(field);
            if (fieldType.isAssignableFrom(type)) {
                setAccessible.invoke(field, true);
                return getFieldValue.invoke(field, (Object) null);
            }
        }
        return null;
    }

    public static Object getStaticFieldValueByTypeName(Class<?> clazz, String simpleTypeName) throws Throwable {
        Object[] fields = (Object[]) getDeclaredFields.invoke(clazz);
        for (Object field : fields) {
            Class<?> type = (Class<?>) getFieldType.invoke(field);
            if (type.getSimpleName().equals(simpleTypeName)) {
                setAccessible.invoke(field, true);
                return getFieldValue.invoke(field, (Object) null);
            }
        }
        return null;
    }

    public static Object getStaticFieldValueByTypeNameContains(Class<?> clazz, String typeNameSubstring) throws Throwable {
        Object[] fields = (Object[]) getDeclaredFields.invoke(clazz);
        for (Object field : fields) {
            Class<?> type = (Class<?>) getFieldType.invoke(field);
            if (type.getName().contains(typeNameSubstring)) {
                setAccessible.invoke(field, true);
                return getFieldValue.invoke(field, (Object) null);
            }
        }
        return null;
    }

    public static void logAllStaticFieldTypes(Class<?> clazz, Logger log) {
        try {
            Object[] fields = (Object[]) getDeclaredFields.invoke(clazz);
            for (Object field : fields) {
                Class<?> type = (Class<?>) getFieldType.invoke(field);
                String name = (String) getFieldName.invoke(field);
                log.warn("  [" + clazz.getSimpleName() + "] " + name + " : " + type.getName());
            }
        } catch (Throwable e) {
            log.warn("logAllStaticFieldTypes failed: " + e.getMessage());
        }
    }

    public static Object invokeNoArgMethodByReturnType(Object instance, Class<?> returnType) throws Throwable {
        Object[] methods = (Object[]) getDeclaredMethods.invoke(instance.getClass());
        for (Object method : methods) {
            Class<?> retType = (Class<?>) getReturnType.invoke(method);
            int paramCount = (int) getParameterCount.invoke(method);
            if (paramCount == 0 && returnType.isAssignableFrom(retType)) {
                setAccessible.invoke(method, true);
                return invokeMethod.invoke(method, instance, new Object[0]);
            }
        }
        return null;
    }

    public static void logAllFieldTypes(Object instance, Logger log) {
        try {
            Class<?> clazz = instance.getClass();
            while (clazz != null && !clazz.getName().equals("java.lang.Object")) {
                Object[] fields = (Object[]) getDeclaredFields.invoke(clazz);
                for (Object field : fields) {
                    Class<?> type = (Class<?>) getFieldType.invoke(field);
                    String name = (String) getFieldName.invoke(field);
                    log.warn("  [" + clazz.getSimpleName() + "] " + name + " : " + type.getName());
                }
                clazz = clazz.getSuperclass();
            }
        } catch (Throwable e) {
            log.warn("logAllFieldTypes failed: " + e.getMessage());
        }
    }

    public static List<Object> invokeAllNoArgMethodsByReturnType(Object instance, Class<?> returnType) throws Throwable {
        List<Object> results = new ArrayList<>();
        Object[] methods = (Object[]) getDeclaredMethods.invoke(instance.getClass());
        for (Object method : methods) {
            Class<?> retType = (Class<?>) getReturnType.invoke(method);
            int paramCount = (int) getParameterCount.invoke(method);
            if (paramCount == 0 && returnType.isAssignableFrom(retType)) {
                setAccessible.invoke(method, true);
                try {
                    Object result = invokeMethod.invoke(method, instance, new Object[0]);
                    results.add(result);
                } catch (Throwable ignored) {
                }
            }
        }
        return results;
    }
}
