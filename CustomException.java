class AgeIsSmallException extends Exception {
    AgeIsSmallException(String m) {
        super(m);
    }
}

public class CustomException {

    public static void age() throws AgeIsSmallException {
        int age = 15;
        if (age < 18) {
            throw new AgeIsSmallException("Age is not over 18, The human is teen");
        }
    }

public static void main(String[] args) {
    try{
            age();
    }catch(AgeIsSmallException e1){
        System.out.println(e1.getMessage());
    }
}
}